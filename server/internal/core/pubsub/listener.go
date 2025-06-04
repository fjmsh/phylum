package pubsub

import (
	"context"
	"errors"
	"sync"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

type listener struct {
	pool *pgxpool.Pool
	conn *pgx.Conn
	mu   sync.Mutex
}

func newListener(pool *pgxpool.Pool, ctx context.Context) (*listener, error) {
	l := listener{
		pool: pool,
		mu:   sync.Mutex{},
	}
	if err := l.connect(ctx); err != nil {
		return nil, err
	}

	return &l, nil
}

func (l *listener) connect(ctx context.Context) error {
	l.mu.Lock()
	defer l.mu.Unlock()

	if l.conn != nil {
		return errors.New("listener is already connected")
	}
	conn, err := l.pool.Acquire(ctx)
	if err != nil {
		return err
	}
	l.conn = conn.Hijack()
	return nil
}

func (l *listener) listen(ctx context.Context, channelName string) error {
	l.mu.Lock()
	defer l.mu.Unlock()

	_, err := l.conn.Exec(ctx, "LISTEN "+channelName)
	return err
}

func (l *listener) unlisten(ctx context.Context, channelName string) error {
	l.mu.Lock()
	defer l.mu.Unlock()

	_, err := l.conn.Exec(ctx, "UNLISTEN "+channelName)
	return err
}

func (l *listener) waitForNotification(ctx context.Context) (*pgconn.Notification, error) {
	l.mu.Lock()
	defer l.mu.Unlock()

	return l.conn.WaitForNotification(ctx)
}
