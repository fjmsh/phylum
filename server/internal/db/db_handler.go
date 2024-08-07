package db

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shroff/phylum/server/internal/db/migrations"
	"github.com/sirupsen/logrus"
)

var (
	ErrMigrationTargetTooLow    = errors.New("schema migration target cannot be less than 0")
	ErrMigrationTargetTooHigh   = errors.New("schema migration target cannot be greater than latest")
	ErrMigrationNoAutoDowngrade = errors.New("will not auto-downgrade schema to prevent data loss")
)

var currentSchemaVersion int
var latestSchemaVersion int

type DbHandler struct {
	Queries
	pool *pgxpool.Pool
}

func NewDb(ctx context.Context, dsn string, trace bool) (*DbHandler, error) {
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, errors.New("Unable to parse DSN: " + err.Error())
	}

	if trace {
		config.ConnConfig.Tracer = tracer{}
	}

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, errors.New("Unable to connect to database: " + err.Error())
	}

	logrus.Info("Connected to " + config.ConnConfig.Database + " at " + config.ConnConfig.Host + ":" + fmt.Sprint(config.ConnConfig.Port))

	conn, err := pool.Acquire(ctx)
	if err != nil {
		return nil, err
	}
	migrator, err := migrations.NewMigrator(ctx, conn.Conn())
	if err != nil {
		return nil, err
	}
	currentSchemaVersion, err = migrator.GetCurrentVersion(ctx)
	if err != nil {
		return nil, err
	}
	latestSchemaVersion = migrator.GetLatestVersion()
	conn.Release()

	handler := &DbHandler{
		Queries: *New(pool),
		pool:    pool,
	}

	return handler, nil
}

func (d DbHandler) WithTx(ctx context.Context, fn func(*DbHandler) error) error {
	return pgx.BeginFunc(ctx, d.pool, func(tx pgx.Tx) error {
		d := DbHandler{
			Queries: *d.Queries.WithTx(tx),
			pool:    d.pool,
		}
		return fn(&d)
	})
}

func (d DbHandler) Exec(ctx context.Context, stmt string, args ...any) error {
	_, err := d.Queries.db.Exec(ctx, stmt, args...)
	return err
}

func (d DbHandler) Close() {
	d.pool.Close()
}
