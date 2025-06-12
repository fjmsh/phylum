package db

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type Handler interface {
	Query(stmt string, args ...interface{}) (pgx.Rows, error)
	QueryRow(stmt string, args ...interface{}) pgx.Row
	ExecNoTx(stmt string, args ...interface{}) (pgconn.CommandTag, error)
	RunInTx(fn func(TxHandler) error) error
}

type TxHandler interface {
	Handler
	Exec(stmt string, args ...interface{}) (pgconn.CommandTag, error)
	CopyFrom(tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error)
	SendBatch(batch *pgx.Batch) pgx.BatchResults
	Tx() pgx.Tx
}

type handler struct {
	ctx context.Context
	tx  interface {
		Begin(context.Context) (pgx.Tx, error)
		Query(context.Context, string, ...interface{}) (pgx.Rows, error)
		QueryRow(context.Context, string, ...interface{}) pgx.Row
		Exec(context.Context, string, ...interface{}) (pgconn.CommandTag, error)
	}
}

func (h handler) Query(stmt string, args ...interface{}) (pgx.Rows, error) {
	return h.tx.Query(h.ctx, stmt, args...)
}

func (h handler) QueryRow(stmt string, args ...interface{}) pgx.Row {
	return h.tx.QueryRow(h.ctx, stmt, args...)
}
func (h handler) ExecNoTx(stmt string, args ...interface{}) (pgconn.CommandTag, error) {
	return h.tx.Exec(h.ctx, stmt, args...)
}

func (h handler) RunInTx(fn func(TxHandler) error) error {
	return pgx.BeginFunc(h.ctx, h.tx, func(tx pgx.Tx) error {
		h := txHandler{
			ctx: h.ctx,
			tx:  tx,
		}
		return fn(h)
	})
}

type txHandler struct {
	ctx context.Context
	tx  pgx.Tx
}

func (h txHandler) Query(stmt string, args ...interface{}) (pgx.Rows, error) {
	return h.tx.Query(h.ctx, stmt, args...)
}

func (h txHandler) QueryRow(stmt string, args ...interface{}) pgx.Row {
	return h.tx.QueryRow(h.ctx, stmt, args...)
}

func (h txHandler) RunInTx(fn func(TxHandler) error) error {
	return pgx.BeginFunc(h.ctx, h.tx, func(tx pgx.Tx) error {
		h := txHandler{
			ctx: h.ctx,
			tx:  tx,
		}
		return fn(h)
	})
}

func (h txHandler) Exec(stmt string, args ...interface{}) (pgconn.CommandTag, error) {
	return h.tx.Exec(h.ctx, stmt, args...)
}

// Part of the interface
func (h txHandler) ExecNoTx(stmt string, args ...interface{}) (pgconn.CommandTag, error) {
	return h.tx.Exec(h.ctx, stmt, args...)
}

func (h txHandler) CopyFrom(tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error) {
	return h.tx.CopyFrom(h.ctx, tableName, columnNames, rowSrc)
}

func (h txHandler) SendBatch(batch *pgx.Batch) pgx.BatchResults {
	return h.tx.SendBatch(h.ctx, batch)
}

func (h txHandler) Tx() pgx.Tx {
	return h.tx
}
