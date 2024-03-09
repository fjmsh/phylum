package library

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
)

type Manager struct {
	queries sql.Queries
	cs      storage.Storage
}

func NewManager(conn *pgx.Conn) Manager {
	queries := *sql.New(conn)
	cs, err := storage.NewLocalStorage("srv")
	if err != nil {
		panic(err)
	}
	return Manager{queries: queries, cs: cs}
}

func (b Manager) Get(ctx context.Context, name string) (*Library, error) {
	// TODO: Permissions checks
	lib, err := b.queries.LibraryByName(ctx, name)
	if err != nil {
		return nil, err
	}

	return &Library{queries: b.queries, root: lib.ID, cs: b.cs}, nil
}

func (b Manager) Create(ctx context.Context, id uuid.UUID, name string) error {
	if _, err := b.queries.LibraryByName(ctx, name); err == nil {
		return fmt.Errorf("root directory already exists: %s", name)
	} else {
		return b.queries.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: nil, Name: name, Dir: true})
	}
}

func (b Manager) Delete(ctx context.Context, name string) error {
	if lib, err := b.Get(ctx, name); err == nil {
		return lib.DeleteRecursive(ctx, lib.root, true)
	} else {
		return fmt.Errorf("root directory does not exist: %s", name)
	}
}
