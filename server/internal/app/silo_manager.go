package app

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/sql"
)

func (a App) CreateSilo(ctx context.Context, id uuid.UUID, owner, storage, name string) error {
	return a.Db.RunInTx(ctx, func(q *sql.Queries) error {
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

func (a App) ListSilos(ctx context.Context) ([]sql.Silo, error) {
	return a.Db.Queries().ListSilos(ctx)
}

func (a App) FindSilo(ctx context.Context, idOrName string) (*core.Silo, error) {
	var silo sql.Silo

	if id, err := uuid.Parse(idOrName); err == nil {
		silo, err = a.Db.Queries().SiloById(ctx, id)
		if err != nil {
			return nil, err
		}
	} else {
		silo, err = a.Db.Queries().SiloByName(ctx, idOrName)
		if err != nil {
			return nil, err
		}
	}

	storage := a.FindStorageBackend(silo.Storage)
	if storage == nil {
		return nil, errors.New("storage backend not found for " + silo.Name + "(" + silo.ID.String() + ")")
	}

	return core.NewSilo(a.Db, storage, silo.ID, silo.Name), nil
}

func (a App) DeleteSilo(ctx context.Context, id uuid.UUID) error {
	data, err := a.Db.Queries().SiloById(ctx, id)
	if err != nil {
		return err
	}
	storage := a.FindStorageBackend(data.Storage)
	if storage == nil {
		return errors.New("storage backend not found for " + id.String())
	}

	silo := core.NewSilo(a.Db, storage, data.ID, data.Name)
	if err := silo.DeleteRecursive(ctx, id, true); err != nil {
		return err
	}
	return a.Db.Queries().DeleteSilo(ctx, id)
}
