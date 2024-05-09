package sql

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/sirupsen/logrus"
)

type DbHandler struct {
	conn    *pgx.Conn
	queries *Queries
}

func NewDb(dsn string, trace bool) (*DbHandler, error) {
	config, err := pgx.ParseConfig(dsn)
	if err != nil {
		return nil, errors.New("Unable to parse DSN: " + err.Error())
	}

	if trace {
		config.Tracer = tracer{}
	}

	conn, err := pgx.ConnectConfig(context.Background(), config)
	if err != nil {
		return nil, errors.New("Unable to connect to database: " + err.Error())
	}

	logrus.Info("Connected to " + config.Database + " at " + config.Host + ":" + fmt.Sprint(config.Port))

	return &DbHandler{
		conn:    conn,
		queries: &Queries{db: conn},
	}, nil
}

func (d DbHandler) Queries() *Queries {
	return d.queries
}

func (d DbHandler) RunInTx(ctx context.Context, fn func(*Queries) error) error {
	return pgx.BeginFunc(ctx, d.conn, func(tx pgx.Tx) error {
		q := d.queries.WithTx(tx)
		return fn(q)
	})
}

func (d DbHandler) Close(ctx context.Context) {
	d.conn.Close(ctx)
}
