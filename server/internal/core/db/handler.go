package db

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type Handler struct {
	ctx context.Context
	tx  interface {
		Begin(context.Context) (pgx.Tx, error)
		SendBatch(context.Context, *pgx.Batch) pgx.BatchResults
		Exec(context.Context, string, ...interface{}) (pgconn.CommandTag, error)
		Query(context.Context, string, ...interface{}) (pgx.Rows, error)
		QueryRow(context.Context, string, ...interface{}) pgx.Row
		CopyFrom(context.Context, pgx.Identifier, []string, pgx.CopyFromSource) (int64, error)
	}
}

func (h Handler) RunInTx(fn func(Handler) error) error {
	return pgx.BeginFunc(h.ctx, h.tx, func(tx pgx.Tx) error {
		h := Handler{
			ctx: h.ctx,
			tx:  tx,
		}
		return fn(h)
	})
}

func (h Handler) Exec(stmt string, args ...interface{}) (pgconn.CommandTag, error) {
	return h.tx.Exec(h.ctx, stmt, args...)
}

func (h Handler) Query(stmt string, args ...interface{}) (pgx.Rows, error) {
	return h.tx.Query(h.ctx, stmt, args...)
}

func (h Handler) QueryRow(stmt string, args ...interface{}) pgx.Row {
	return h.tx.QueryRow(h.ctx, stmt, args...)
}

func (h Handler) CopyFrom(tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error) {
	return h.tx.CopyFrom(h.ctx, tableName, columnNames, rowSrc)
}

func (h Handler) SendBatch(batch *pgx.Batch) pgx.BatchResults {
	return h.tx.SendBatch(h.ctx, batch)
}
