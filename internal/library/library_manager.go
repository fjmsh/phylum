package library

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
)

type Manager struct {
	db             *sql.DbHandler
	storageManager *storage.Manager
}

func NewManager(db *sql.DbHandler, storageManager *storage.Manager) (*Manager, error) {
	return &Manager{db: db, storageManager: storageManager}, nil
}

func (b Manager) Get(ctx context.Context, id uuid.UUID) (*Library, error) {
	// TODO: Permissions checks
	lib, err := b.db.Queries().LibraryById(ctx, id)
	if err != nil {
		return nil, err
	}
	cs := b.storageManager.Find(lib.StorageBackend)
	if cs == nil {
		return nil, errors.New("storage backend not found: " + lib.StorageBackend)
	}

	return &Library{db: b.db, root: lib.ID, cs: cs}, nil
}

func (b Manager) Create(ctx context.Context, id uuid.UUID, storageBackend string, owner int32, displayName string) error {
	return b.db.RunInTx(ctx, func(q *sql.Queries) error {
		if err := q.CreateLibrary(ctx, sql.CreateLibraryParams{
			ID:             id,
			StorageBackend: storageBackend,
			Owner:          owner,
			DisplayName:    displayName,
		}); err != nil {
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
