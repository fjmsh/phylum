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
	db     db.Handler
	logger zerolog.Logger
	// Config
	config         Config
	defaultTimeout time.Duration
	// Running
	factories        map[string]workUnitFactory
	availableWorkers chan struct{}
	// Job availability
	subJobInserted   pubsub.Subscription
	muJobAvailable   *sync.Mutex
	condJobAvailable *sync.Cond
	// Shutdown
	wg           sync.WaitGroup
	done         chan struct{}
	cancelListen context.CancelFunc
	cancelRun    context.CancelFunc
	cancelWork   context.CancelFunc
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
	if c.subJobInserted != nil {
		return errors.New("already started")
	}
	if c.config.Workers <= 0 {
		return errors.New("workers must be a positive integer")
	}
	if err := resetRunningJobs(c.db); err != nil {
		return err
	}
	if _, err := enqueueScheduledJobs(c.db); err != nil {
		return err
	}

	c.availableWorkers = make(chan struct{}, c.config.Workers)
	c.muJobAvailable = &sync.Mutex{}
	c.condJobAvailable = &sync.Cond{L: c.muJobAvailable}
	c.defaultTimeout = time.Duration(c.config.Timeout) * time.Second

	c.logger.Info().Int("workers", c.config.Workers).Msg("Starting")
	c.subJobInserted = notifier.Listen(channelName)
	c.done = make(chan struct{})

	var listenCtx, runCtx, workCtx context.Context
	listenCtx, c.cancelListen = context.WithCancel(ctx)
	runCtx, c.cancelRun = context.WithCancel(ctx)
	workCtx, c.cancelWork = context.WithCancel(ctx)
	go c.produceJobs(listenCtx)
	go c.consumeJobs(runCtx, workCtx)

	// Wait until the listener is established
	select {
	case <-c.subJobInserted.EstablishedC():
	default:
	}

	return nil
}

func (c *Client) Stop(ctx context.Context, hard bool) bool {
	c.logger.Info().Bool("hard", hard).Msg("Stop")
	c.cancelListen()
	c.cancelRun()
	if hard {
		c.cancelWork()
	}

	select {
	case <-ctx.Done(): // stop context cancelled
		c.logger.Warn().Msg("Stop timeout reached. Some jobs still running")
		return false
	case <-c.done:
		return true
	}
}

func (c *Client) produceJobs(ctx context.Context) {
	t := time.NewTicker(5 * time.Second)
	for {
		select {
		case <-ctx.Done():
			return
		case <-c.subJobInserted.NotificationC():
			c.condJobAvailable.Signal()
		case <-t.C:
			if n, err := enqueueScheduledJobs(c.db); err != nil {
				c.logger.Warn().Err(err).Msg("Error enqueueing scheduled jobs")
			} else if n > 0 {
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
					// No available jobs. Wait for signal
					c.muJobAvailable.Lock()
					c.condJobAvailable.Wait()
					c.muJobAvailable.Unlock()
					// Make sure to mark the worker as available
					<-c.availableWorkers
				} else {
					// Unknown error
					// TODO: Maybe try again (after a short delay) a couple of times before fatal?
					c.logger.Fatal().Err(err).Msg("Failed to claim job")
				}
			} else {
				c.logger.Trace().Int32("id", info.ID).Str("kind", info.Kind).Bytes("args", info.EncodedArgs).Msg("Executing job")
				c.execute(workCtx, info)
			}
		}
	}
	c.wg.Wait()
	close(c.done)
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

	c.wg.Add(1)
	go func() {
		defer func() {
			c.wg.Done()
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
	scheduleAt := computeBackoff(info.Attempt)
	c.logger.
		Warn().
		Err(err).
		Int32("id", info.ID).
		Int("attempt", info.Attempt+1).
		Msg("Error executing job")
	return updateJobStatusError(
		c.db,
		info.ID,
		AttemptError{
			At:    time.Now(),
			Error: err.Error(),
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
