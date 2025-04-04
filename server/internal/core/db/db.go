package db

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/sirupsen/logrus"
)

var DatabaseURL string
var TraceSQL bool
var AutoMigrate bool

var pool *pgxpool.Pool

func Get(ctx context.Context) Handler {
	if pool == nil {
		if p, err := createPool(context.Background(), DatabaseURL, TraceSQL, AutoMigrate); err != nil {
			logrus.Fatal(err)
		} else {
			pool = p
		}
	}
	return Handler{
		ctx: ctx,
		tx:  pool,
	}
}
func Close() {
	if pool != nil {
		pool.Close()
		pool = nil
	}
}

func createPool(ctx context.Context, dsn string, traceSQL, autoMigrate bool) (*pgxpool.Pool, error) {
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

	if err := checkVersion(ctx, autoMigrate); err != nil {
		return nil, err
	}

	return pool, nil
}
