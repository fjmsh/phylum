package jobs

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"github.com/riverqueue/river/rivermigrate"
	"github.com/sirupsen/logrus"
)

// var client river.Client

var client *river.Client[pgx.Tx]

func Initialize(ctx context.Context, pool *pgxpool.Pool) error {
	logrus.Info("Initializing Jobs")
	if client != nil {
		return errors.New("jobs already initialized")
	}

	if m, err := rivermigrate.New(riverpgxv5.New(pool), nil); err != nil {
		return err
	} else if _, err := m.Migrate(ctx, rivermigrate.DirectionUp, nil); err != nil {
		return err
	}

	workers := river.NewWorkers()
	river.AddWorker(workers, &MigrateWorker{})
	river.AddWorker(workers, &DeleteContentsWorker{})

	if c, err := river.NewClient(riverpgxv5.New(pool), &river.Config{
		Queues: map[string]river.QueueConfig{
			river.QueueDefault: {MaxWorkers: 5},
		},
		Workers: workers,
	}); err != nil {
		return err
	} else {
		client = c
	}
	return client.Start(ctx)
}

func Shutdown(ctx context.Context) {
	logrus.Info("Stopping Jobs")
	gracefulCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := client.Stop(gracefulCtx); err != nil {
		logrus.Info("No more Mr. Nice Guy")
		hardStopCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
		defer cancel()
		if err := client.StopAndCancel(hardStopCtx); err != nil {
			logrus.Warn("Could not stop and cancel jobs: " + err.Error())
		}
	}
}
