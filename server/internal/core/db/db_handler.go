package db

import (
	"context"
	"errors"
	"fmt"

	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/sirupsen/logrus"
)

var (
	ErrMigrationTargetTooLow    = errors.New("schema migration target cannot be less than 0")
	ErrMigrationTargetTooHigh   = errors.New("schema migration target cannot be greater than latest")
	ErrMigrationNoAutoDowngrade = errors.New("will not auto-downgrade schema to prevent data loss")
)

type DbHandler struct {
	Queries
	tx interface {
		Begin(context.Context) (pgx.Tx, error)
	}
	pool *pgxpool.Pool
}

var d *DbHandler
var DatabaseURL string
var TraceSQL bool
var AutoMigrate bool

var pg *goqu.Database

func init() {
	pg = goqu.New("postgres", nil)
	goqu.SetDefaultPrepared(true)
}

func Get() *DbHandler {
	if d == nil {
		if db, err := create(context.Background(), DatabaseURL, TraceSQL, AutoMigrate); err != nil {
			logrus.Fatal(err)
		} else {
			d = db
		}
	}
	return d
}
func Close() {
	if d != nil {
		d.pool.Close()
		d = nil
	}
}

func create(ctx context.Context, dsn string, traceSQL, autoMigrate bool) (*DbHandler, error) {
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, errors.New("Unable to parse DSN: " + err.Error())
	}

	if traceSQL {
		config.ConnConfig.Tracer = tracer{}
	}

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, errors.New("Unable to connect to database: " + err.Error())
	}

	logrus.Debug("Connected to " + config.ConnConfig.Database + " at " + config.ConnConfig.Host + ":" + fmt.Sprint(config.ConnConfig.Port))

	d := DbHandler{
		Queries: *New(pool),
		tx:      pool,
		pool:    pool,
	}

	if err := d.checkVersion(ctx, autoMigrate); err != nil {
		return nil, err
	}

	return &d, nil
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
