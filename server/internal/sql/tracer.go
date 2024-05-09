package sql

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/sirupsen/logrus"
)

type tracer struct {
}

func (t tracer) TraceQueryStart(ctx context.Context, conn *pgx.Conn, data pgx.TraceQueryStartData) context.Context {
	logrus.Trace(data)
	return ctx
}

func (c tracer) TraceQueryEnd(ctx context.Context, conn *pgx.Conn, data pgx.TraceQueryEndData) {
	logrus.Trace(data)
}
