package core

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
)

type FileSystem struct {
	db             *sql.DbHandler
	storageManager *storage.Manager
}

func OpenFileSystem(db *sql.DbHandler, storageManager *storage.Manager) *FileSystem {
	return &FileSystem{db: db, storageManager: storageManager}
}

func (fs FileSystem) CreateSilo(ctx context.Context, id uuid.UUID, owner int32, storage string, name string) error {
	return fs.db.RunInTx(ctx, func(q *sql.Queries) error {
		if err := q.CreateSilo(ctx, sql.CreateSiloParams{
			ID:      id,
			Owner:   owner,
			Storage: storage,
			Name:    name,
		}); err != nil {
			return err
		}
		return q.CreateResource(ctx, sql.CreateResourceParams{
			ID:     id,
			Parent: nil,
			Name:   id.String(),
			Dir:    true,
		})
	})
}

func (fs FileSystem) ListSilos(ctx context.Context) ([]sql.Silo, error) {
	return fs.db.Queries().ListSilos(ctx)
}

func (fs FileSystem) OpenSilo(ctx context.Context, id uuid.UUID) (*Silo, error) {
	silo, err := fs.db.Queries().SiloById(ctx, id)
	if err != nil {
		return nil, err
	}
	storage := fs.storageManager.Find(silo.Storage)
	if storage == nil {
		return nil, errors.New("storage backend not found for " + id.String())
	}

	return &Silo{
		db:      fs.db,
		storage: storage,
		root:    silo.ID,
	}, nil
}

func (fs FileSystem) DeleteSilo(ctx context.Context, id uuid.UUID) error {
	data, err := fs.db.Queries().SiloById(ctx, id)
	if err != nil {
		return err
	}
	storage := fs.storageManager.Find(data.Storage)
	if storage == nil {
		return errors.New("storage backend not found for " + id.String())
	}

	silo := &Silo{
		db:      fs.db,
		storage: storage,
		root:    data.ID,
	}
	if err := silo.DeleteRecursive(ctx, id, true); err != nil {
		return err
	}
	return fs.db.Queries().DeleteSilo(ctx, id)
}
