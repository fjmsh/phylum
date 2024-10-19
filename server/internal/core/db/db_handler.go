package db

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/sirupsen/logrus"
)

var (
	ErrMigrationTargetTooLow    = errors.New("schema migration target cannot be less than 0")
	ErrMigrationTargetTooHigh   = errors.New("schema migration target cannot be greater than latest")
	ErrMigrationNoAutoDowngrade = errors.New("will not auto-downgrade schema to prevent data loss")
)

var Default *DbHandler

type DbHandler struct {
	Queries
	tx interface {
		Begin(context.Context) (pgx.Tx, error)
	}
	pool *pgxpool.Pool
}

func Initialize(ctx context.Context, dsn string, autoMigrate, trace bool) error {
	if Default != nil {
		return nil
	}
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return errors.New("Unable to parse DSN: " + err.Error())
	}

	if trace {
		config.ConnConfig.Tracer = tracer{}
	}

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return errors.New("Unable to connect to database: " + err.Error())
	}

	logrus.Debug("Connected to " + config.ConnConfig.Database + " at " + config.ConnConfig.Host + ":" + fmt.Sprint(config.ConnConfig.Port))

	Default = &DbHandler{
		Queries: *New(pool),
		tx:      pool,
		pool:    pool,
	}

	Default.checkVersion(ctx, autoMigrate)

	return nil
}

func (d DbHandler) WithTx(ctx context.Context, fn func(*DbHandler) error) error {
	return pgx.BeginFunc(ctx, d.tx, func(tx pgx.Tx) error {
		d := DbHandler{
			Queries: *d.Queries.WithTx(tx),
			tx:      tx,
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
