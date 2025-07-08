package db

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/rs/zerolog"
)

type tracer struct {
	log zerolog.Logger
}

func (t tracer) TraceQueryStart(ctx context.Context, conn *pgx.Conn, data pgx.TraceQueryStartData) context.Context {
	t.log.Trace().Any("data", data).Msg("query start")
	return ctx
}

func (t tracer) TraceQueryEnd(ctx context.Context, conn *pgx.Conn, data pgx.TraceQueryEndData) {
	t.log.Trace().Any("data", data).Msg("query end")
}
