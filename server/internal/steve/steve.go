package steve

import (
	"context"
	"encoding/json"
	"errors"
	"sync"
	"time"

	"codeberg.org/shroff/phylum/server/internal/pubsub"
	"github.com/jackc/pgx/v5"
	"github.com/sirupsen/logrus"
)

const channelName = "job_inserted"
const maxAttempts = 6

type Client struct {
	db               db
	workers          *Workers
	sem              chan struct{}
	condJobAvailable *sync.Cond

	sub          pubsub.Subscription
	cancelListen context.CancelFunc
	cancelRun    context.CancelFunc
	cancelWork   context.CancelFunc
}

func NewClient(db db, workers *Workers, queueSize, concurrency int) *Client {
	cond := &sync.Cond{}
	return &Client{
		db:               db,
		workers:          workers,
		sem:              make(chan struct{}, concurrency),
		condJobAvailable: cond,
	}
}

func (c *Client) Start(ctx context.Context, notifier pubsub.Notifier) error {
	if c.sub != nil {
		return errors.New("already started")
	}
	c.sub = notifier.Listen(channelName)

	if err := resetRunningJobs(ctx, c.db); err != nil {
		return err
	}

	var listenCtx, runCtx, workCtx context.Context
	listenCtx, c.cancelListen = context.WithCancel(ctx)
	runCtx, c.cancelRun = context.WithCancel(ctx)
	workCtx, c.cancelWork = context.WithCancel(ctx)
	go c.produceJobs(listenCtx)
	go c.consumeJobs(runCtx, workCtx)

	// Wait until the listener is established
	select {
	case <-c.sub.EstablishedC():
	default:
	}

	return nil
}

func (c *Client) produceJobs(ctx context.Context) {
	t := time.NewTicker(5 * time.Second)
	for {
		select {
		case <-ctx.Done():
			return
		case <-c.sub.NotificationC():
			c.condJobAvailable.Signal()
		case <-t.C:
			enqueueScheduledJobs(ctx, c.db)
		}
	}
}

func (c *Client) consumeJobs(runCtx context.Context, workCtx context.Context) {
loop:
	for {
		select {
		case <-runCtx.Done():
			break loop
		// Wait for worker to become available
		case c.sem <- struct{}{}:
			if info, err := claimNextJob(runCtx, c.db); err != nil {
				if errors.Is(err, errNoJobs) {
					// No available jobs. Wait for signal
					c.condJobAvailable.Wait()
					// Make sure to put the worker back in the queue
					<-c.sem
				} else {
					// Unknown error
					// TODO: Maybe try again (after a short delay) a couple of times before fatal?
					logrus.Fatal(err)
				}
			} else {
				c.execute(workCtx, info)
			}
		}
	}
}

func (c *Client) execute(ctx context.Context, info *JobInfo) {
	w, err := c.workers.createWork(info)

	if err != nil {
		logrus.Warn("Error executing job: " + err.Error())
		c.db.BeginFunc(context.Background(), func(tx pgx.Tx) error {
			return updateJobStatusError(ctx, tx, info.ID, AttemptError{
				At:      time.Now(),
				Attempt: info.Attempt + 1,
				Error:   err.Error(),
			}, computeBackoff(info.Attempt+1))
		})
	}

	if t := w.Timeout(); t != 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, t)
		defer cancel()
	}

	go func() {
		defer func() {
			<-c.sem
		}()
		if err := w.Work(ctx); err != nil {
			logrus.Warn(err)
			// computeBackoff(int(w.JobID())
			// w.NextRetry()
			// TODO: log error?
			// TODO: record error in db
			// TODO: reschedule
		} else {
			c.db.BeginFunc(context.Background(), func(tx pgx.Tx) error {
				return updateJobStatus(ctx, tx, info.ID, JobStatusCompleted)
			})
		}
	}()
}

func (c *Client) InsertJob(ctx context.Context, tx pgx.Tx, args JobArgs) error {
	return c.InsertJobs(ctx, tx, []JobArgs{args})
}

func (c *Client) InsertJobs(ctx context.Context, tx pgx.Tx, args []JobArgs) error {
	params := make([]insertJobParams, len(args))
	for i, a := range args {
		encodedArgs, err := json.Marshal(a)
		if err != nil {
			return err
		}

		params[i] = insertJobParams{
			Kind:        a.Kind(),
			EncodedArgs: encodedArgs,
		}
	}
	_, err := insertJobs(ctx, tx, params)
	return err
}
