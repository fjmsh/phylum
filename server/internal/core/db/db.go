package db

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/sirupsen/logrus"
)

var h *Handler
var DatabaseURL string
var TraceSQL bool
var AutoMigrate bool

func Get() *Handler {
	if h == nil {
		if handler, err := createHandler(context.Background(), DatabaseURL, TraceSQL, AutoMigrate); err != nil {
			logrus.Fatal(err)
		} else {
			h = handler
		}
	}
	return h
}
func Close() {
	if h != nil {
		h.pool.Close()
		h = nil
	}
}

func createHandler(ctx context.Context, dsn string, traceSQL, autoMigrate bool) (*Handler, error) {
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

	h := Handler{
		tx:   pool,
		pool: pool,
	}

	if err := h.checkVersion(ctx, autoMigrate); err != nil {
		return nil, err
	}

	return &h, nil
}
