package steve

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/pubsub"
	"github.com/rs/zerolog"
)

const channelName = "job_inserted"
const maxAttempts = 6

type Client struct {
	config           Config
	db               db.Handler
	logger           zerolog.Logger
	factories        map[string]workUnitFactory
	availableWorkers chan struct{}
	muJobAvailable   *sync.Mutex
	condJobAvailable *sync.Cond
	sub              pubsub.Subscription
	cancelListen     context.CancelFunc
	cancelRun        context.CancelFunc
	cancelWork       context.CancelFunc
	// Config
	defaultTimeout time.Duration
}

func NewClient(db db.Handler, logger zerolog.Logger, config Config) *Client {
	return &Client{
		config:    config,
		db:        db,
		logger:    logger.With().Str("mod", "steve").Logger(),
		factories: make(map[string]workUnitFactory),
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
	client.logger.Debug().Str("kind", kind).Msg("Registering worker")
	if _, ok := client.factories[kind]; ok {
		panic(fmt.Errorf("worker for kind %q is already registered", kind))
	}
	client.factories[kind] = &typedWorkUnitFactory[T]{worker: worker}
}

func (c *Client) Start(ctx context.Context, notifier pubsub.Notifier) error {
	if c.sub != nil {
		return errors.New("already started")
	}
	if c.config.Workers <= 0 {
		return errors.New("workers must be a positive integer")
	}
	c.availableWorkers = make(chan struct{}, c.config.Workers)
	c.muJobAvailable = &sync.Mutex{}
	c.condJobAvailable = &sync.Cond{L: c.muJobAvailable}
	c.defaultTimeout = time.Duration(c.config.Timeout) * time.Second

	c.logger.Info().Int("workers", c.config.Workers).Msg("Starting Job Processing")
	c.sub = notifier.Listen(channelName)

	if err := resetRunningJobs(c.db); err != nil {
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
			c.logger.Debug().Msg("Job available")
			c.condJobAvailable.Signal()
		case <-t.C:
			if n, err := enqueueScheduledJobs(c.db); err != nil {
				c.logger.Warn().Err(err).Msg("Error enqueueing scheduled jobs")
			} else if n > 0 {
				c.logger.Debug().Int("count", n).Msg("Enqueued scheduled jobs")
				c.condJobAvailable.Signal()
			}
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
			if info, err := claimNextJob(c.db); err != nil {
				if errors.Is(err, errNoJobs) {
					c.logger.Debug().Msg("No jobs available. Sleeping until notified")
					// No available jobs. Wait for signal
					c.muJobAvailable.Lock()
					c.condJobAvailable.Wait()
					c.muJobAvailable.Unlock()
					c.logger.Debug().Msg("New job!!")
					// Make sure to mark the worker as available
					<-c.availableWorkers
				} else {
					// Unknown error
					// TODO: Maybe try again (after a short delay) a couple of times before fatal?
					c.logger.Fatal().Err(err).Msg("Failed to claim job")
				}
			} else {
				c.logger.Debug().Int32("id", info.ID).Str("kind", info.Kind).Bytes("args", info.EncodedArgs).Msg("Executing job")
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
		c.recordError(info, err)
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
			c.recordError(info, err)
		} else {
			updateJobStatus(c.db, info.ID, JobStatusCompleted)
		}
	}()
}

func (c *Client) recordError(info *JobInfo, err error) error {
	scheduleAt := computeBackoff(info.Attempt + 1)
	c.logger.Warn().Err(err).Int32("id", info.ID).Str("kind", info.Kind).Bytes("args", info.EncodedArgs).Time("schedule_at", scheduleAt.Time).Msg("Error executing jobs")
	return updateJobStatusError(
		c.db,
		info.ID,
		AttemptError{
			At:      time.Now(),
			Attempt: info.Attempt + 1,
			Error:   err.Error(),
		},
		scheduleAt,
	)

}

func (c *Client) InsertJob(db db.Handler, args JobArgs) error {
	return c.InsertJobs(db, []JobArgs{args})
}

func (c *Client) InsertJobs(db db.Handler, args []JobArgs) error {
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
	_, err := insertJobs(db, params)
	return err
}
