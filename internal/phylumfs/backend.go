package phylumfs

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/sql"
)

type Backend interface {
	FindRoot(ctx context.Context, name string) (Fs, error)
	Mkroot(ctx context.Context, id uuid.UUID, name string) error
	Rmroot(ctx context.Context, name string) error
}

type pgxBackend struct {
	queries sql.Queries
	cs      contentStore
}

func New(conn *pgx.Conn) Backend {
	queries := *sql.New(conn)
	cs, err := newLocalContentStore("srv")
	if err != nil {
		panic(err)
	}
	return pgxBackend{queries: queries, cs: cs}
}

func (b pgxBackend) FindRoot(ctx context.Context, name string) (Fs, error) {
	// TODO: Permissions checks
	root, err := b.queries.FindRoot(ctx, name)
	if err != nil {
		return nil, err
	}

	return pgxFs{queries: b.queries, root: root.ID, cs: b.cs}, nil
}

func (b pgxBackend) Mkroot(ctx context.Context, id uuid.UUID, name string) error {
	if _, err := b.queries.FindRoot(ctx, name); err == nil {
		return fmt.Errorf("root directory already exists: %s", name)
	} else {
		return b.queries.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: nil, Name: name, Dir: true})
	}
}

func (b pgxBackend) Rmroot(ctx context.Context, name string) error {
	if fs, err := b.FindRoot(ctx, name); err == nil {
		return fs.DeleteRecursive(ctx, fs.rootId())
	} else {
		return fmt.Errorf("root directory does not exist: %s", name)
	}
}
