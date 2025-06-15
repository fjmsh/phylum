package steve

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
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
	factories        map[string]workUnitFactory
	availableWorkers chan struct{}
	condJobAvailable *sync.Cond
	sub              pubsub.Subscription
	cancelListen     context.CancelFunc
	cancelRun        context.CancelFunc
	cancelWork       context.CancelFunc
	// Config
	defaultTimeout time.Duration
}

func NewClient(db db, config Config) *Client {
	cond := &sync.Cond{}
	return &Client{
		db:               db,
		factories:        make(map[string]workUnitFactory),
		availableWorkers: make(chan struct{}, config.Workers),
		condJobAvailable: cond,
		defaultTimeout:   time.Duration(config.Timeout) * time.Second,
	}
}

// RegisterWorker registers a Worker on the provided client. Each Worker must
// be registered so that the Client knows it should handle a specific kind of
// job (as returned by its `Kind()` method).
//
// Note that RegisterWorker will panic if a worker of this kind is already
// registered for this Client
func RegisterWorker[T JobArgs](client *Client, worker Worker[T]) {
	var jobArgs T
	kind := jobArgs.Kind()
	if _, ok := client.factories[kind]; ok {
		panic(fmt.Errorf("worker for kind %q is already registered", kind))
	}
	client.factories[kind] = &typedWorkUnitFactory[T]{worker: worker}
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
		case c.availableWorkers <- struct{}{}:
			if info, err := claimNextJob(runCtx, c.db); err != nil {
				if errors.Is(err, errNoJobs) {
					// No available jobs. Wait for signal
					c.condJobAvailable.Wait()
					// Make sure to mark the worker as available
					<-c.availableWorkers
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
	var w workUnit
	var err error
	if f, ok := c.factories[info.Kind]; !ok {
		err = errors.New("unknown job kind: " + info.Kind)
	} else {
		w, err = f.makeUnit(info)
	}

	if err != nil {
		c.recordError(ctx, info, err)
		return
	}

	if t := w.Timeout(); t != 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, t)
		defer cancel()
	}

	go func() {
		defer func() {
			<-c.availableWorkers
		}()
		if err := w.Work(ctx); err != nil {
			c.recordError(ctx, info, err)
		} else {
			c.db.BeginFunc(context.Background(), func(tx pgx.Tx) error {
				return updateJobStatus(ctx, tx, info.ID, JobStatusCompleted)
			})
		}
	}()
}

func (c *Client) recordError(ctx context.Context, info *JobInfo, err error) error {
	logrus.Warn("Error executing job: " + err.Error())
	return c.db.BeginFunc(context.Background(), func(tx pgx.Tx) error {
		return updateJobStatusError(ctx, tx, info.ID, AttemptError{
			At:      time.Now(),
			Attempt: info.Attempt + 1,
			Error:   err.Error(),
		}, computeBackoff(info.Attempt+1))
	})

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
