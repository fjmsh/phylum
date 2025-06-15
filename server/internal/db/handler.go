package db

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type Handler interface {
	RunInTx(fn func(TxHandler) error) error
	Query(stmt string, args ...interface{}) (pgx.Rows, error)
	QueryRow(stmt string, args ...interface{}) pgx.Row
	Exec(stmt string, args ...interface{}) (pgconn.CommandTag, error)
	CopyFrom(tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error)
}

type TxHandler interface {
	Handler
	Tx() pgx.Tx
}

type handler struct {
	ctx context.Context
	tx  interface {
		Begin(context.Context) (pgx.Tx, error)
		Query(context.Context, string, ...interface{}) (pgx.Rows, error)
		QueryRow(context.Context, string, ...interface{}) pgx.Row
		Exec(context.Context, string, ...interface{}) (pgconn.CommandTag, error)
		CopyFrom(context.Context, pgx.Identifier, []string, pgx.CopyFromSource) (int64, error)
	}
}

func (h handler) RunInTx(fn func(TxHandler) error) error {
	return pgx.BeginFunc(h.ctx, h.tx, func(tx pgx.Tx) error {
		h := txHandler{
			handler: h,
			tx:      tx,
		}
		return fn(h)
	})
}

func (h handler) Query(stmt string, args ...interface{}) (pgx.Rows, error) {
	return h.tx.Query(h.ctx, stmt, args...)
}

func (h handler) QueryRow(stmt string, args ...interface{}) pgx.Row {
	return h.tx.QueryRow(h.ctx, stmt, args...)
}

func (h handler) Exec(stmt string, args ...interface{}) (pgconn.CommandTag, error) {
	return h.tx.Exec(h.ctx, stmt, args...)
}

func (h handler) CopyFrom(tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error) {
	return h.tx.CopyFrom(h.ctx, tableName, columnNames, rowSrc)
}

type txHandler struct {
	handler
	tx pgx.Tx
}

func (h txHandler) Tx() pgx.Tx {
	return h.tx
}
