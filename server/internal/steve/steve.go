package steve

import (
	"context"
	"encoding/json"
	"errors"

	"codeberg.org/shroff/phylum/server/internal/pubsub"
	"github.com/jackc/pgx/v5"
	"github.com/sirupsen/logrus"
)

const channelName = "job_inserted"

type Client struct {
	workers *Workers
	queue   chan WorkUnit
	sub     pubsub.Subscription

	cancelListen context.CancelFunc
	cancelRun    context.CancelFunc
	cancelWork   context.CancelFunc
}

func NewClient(workers *Workers) *Client {
	return &Client{
		workers: workers,
		queue:   make(chan WorkUnit, 100000),
	}
}

func (c *Client) Start(ctx context.Context, notifier pubsub.Notifier, db db) error {
	if c.sub != nil {
		return errors.New("already started")
	}
	c.sub = notifier.Listen(channelName)

	if work, err := restoreJobQueue(ctx, db, c.workers); err != nil {
		for _, w := range work {
			c.queue <- w
		}
	}

	var listenCtx, runCtx, workCtx context.Context
	listenCtx, c.cancelListen = context.WithCancel(ctx)
	runCtx, c.cancelRun = context.WithCancel(ctx)
	workCtx, c.cancelWork = context.WithCancel(ctx)
	go c.listenForJobs(listenCtx)
	go c.run(runCtx, workCtx)

	// Wait until the listener is established
	select {
	case <-c.sub.EstablishedC():
	default:
	}

	return nil
}

// listenForJobs listens for job insert notifications and adds them to the queue
func (c *Client) listenForJobs(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case payload := <-c.sub.NotificationC():
			var job JobRow
			json.Unmarshal([]byte(payload), &job)
			if w, err := c.workers.pkg(&job); err != nil {
				logrus.Warn("Unable to package job: " + err.Error())
			} else {
				c.queue <- w
			}
		}
	}
}

func (c *Client) run(ctx context.Context, workCtx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case w := <-c.queue:
			err := w.Work(workCtx)
			logrus.Warn(err)
		}
	}
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
