package db

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Handler struct {
	tx interface {
		Begin(context.Context) (pgx.Tx, error)
		Exec(context.Context, string, ...interface{}) (pgconn.CommandTag, error)
		Query(context.Context, string, ...interface{}) (pgx.Rows, error)
		QueryRow(context.Context, string, ...interface{}) pgx.Row
		CopyFrom(context.Context, pgx.Identifier, []string, pgx.CopyFromSource) (int64, error)
	}
	pool *pgxpool.Pool
}

func (h Handler) RunInTx(ctx context.Context, fn func(*Handler) error) error {
	return pgx.BeginFunc(ctx, h.tx, func(tx pgx.Tx) error {
		h := Handler{
			tx:   tx,
			pool: h.pool,
		}
		return fn(&h)
	})
}

func (h Handler) Exec(ctx context.Context, stmt string, args ...interface{}) (pgconn.CommandTag, error) {
	return h.tx.Exec(ctx, stmt, args...)
}

func (h Handler) Query(ctx context.Context, stmt string, args ...interface{}) (pgx.Rows, error) {
	return h.tx.Query(ctx, stmt, args...)
}

func (h Handler) QueryRow(ctx context.Context, stmt string, args ...interface{}) pgx.Row {
	return h.tx.QueryRow(ctx, stmt, args...)
}

func (h Handler) CopyFrom(ctx context.Context, tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error) {
	return h.tx.CopyFrom(ctx, tableName, columnNames, rowSrc)
}
