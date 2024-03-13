package library

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
)

type Manager struct {
	db *sql.DbHandler
	cs storage.Storage
}

func NewManager(db *sql.DbHandler) Manager {
	cs, err := storage.NewLocalStorage("srv")
	if err != nil {
		panic(err)
	}
	return Manager{db: db, cs: cs}
}

func (b Manager) Get(ctx context.Context, id uuid.UUID) (*Library, error) {
	// TODO: Permissions checks
	lib, err := b.db.Queries().LibraryById(ctx, id)
	if err != nil {
		return nil, err
	}

	return &Library{db: b.db, root: lib.ID, cs: b.cs}, nil
}

func (b Manager) Create(ctx context.Context, id uuid.UUID, owner int32, displayName string) error {
	return b.db.RunInTx(ctx, func(q *sql.Queries) error {
		if err := q.CreateLibrary(ctx, sql.CreateLibraryParams{ID: id, Owner: owner, DisplayName: displayName}); err != nil {
			return err
		}
		if err := q.CreateResource(ctx, sql.CreateResourceParams{ID: id, Dir: true}); err != nil {
			return err
		}
		return nil
	})
}

func (b Manager) Delete(ctx context.Context, id uuid.UUID) error {
	if lib, err := b.Get(ctx, id); err == nil {
		return lib.DeleteRecursive(ctx, lib.root, true)
	} else {
		return fmt.Errorf("library does not exist: %s", id)
	}
}
