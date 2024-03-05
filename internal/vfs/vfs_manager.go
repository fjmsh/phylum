package vfs

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
)

type VfsManager struct {
	queries sql.Queries
	cs      storage.Storage
}

func NewManager(conn *pgx.Conn) VfsManager {
	queries := *sql.New(conn)
	cs, err := storage.NewLocalStorage("srv")
	if err != nil {
		panic(err)
	}
	return VfsManager{queries: queries, cs: cs}
}

func (b VfsManager) GetVfs(ctx context.Context, name string) (*Vfs, error) {
	// TODO: Permissions checks
	root, err := b.queries.FindRoot(ctx, name)
	if err != nil {
		return nil, err
	}

	return &Vfs{queries: b.queries, root: root.ID, cs: b.cs}, nil
}

func (b VfsManager) CreateVfs(ctx context.Context, id uuid.UUID, name string) error {
	if _, err := b.queries.FindRoot(ctx, name); err == nil {
		return fmt.Errorf("root directory already exists: %s", name)
	} else {
		return b.queries.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: nil, Name: name, Dir: true})
	}
}

func (b VfsManager) DeleteVfs(ctx context.Context, name string) error {
	if fs, err := b.GetVfs(ctx, name); err == nil {
		return fs.DeleteRecursive(ctx, fs.rootId())
	} else {
		return fmt.Errorf("root directory does not exist: %s", name)
	}
}
