package app

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/app/core"
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
		_, err := q.CreateResource(ctx, sql.CreateResourceParams{
			ID:     id,
			Parent: nil,
			Name:   id.String(),
			Dir:    true,
		})
		// TODO: insert permissions

		return err
	})
}

func (a App) AllSilos(ctx context.Context) ([]core.Silo, error) {
	silos, err := a.Db.Queries().ListAllSilos(ctx)
	if err != nil {
		return nil, err
	}
	results := make([]core.Silo, len(silos))
	for i, s := range silos {
		results[i] = core.NewSilo(a.Db, s.Name, s.Owner, s.ID, a.FindStorageBackend(s.Storage))
	}
	return results, nil
}

func (a App) SilosForUser(ctx context.Context, username string) ([]core.Silo, error) {
	silos, err := a.Db.Queries().ListSilosForUser(ctx, username)
	if err != nil {
		return nil, err
	}
	results := make([]core.Silo, len(silos))
	for i, s := range silos {
		results[i] = core.NewSilo(a.Db, s.Name, s.Owner, s.ID, a.FindStorageBackend(s.Storage))
	}
	return results, nil
}

func (a App) FindSilo(ctx context.Context, idOrName string) (core.Silo, error) {
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

	return core.NewSilo(a.Db, silo.Name, silo.Owner, silo.ID, storage), nil
}

func (a App) DeleteSilo(ctx context.Context, id uuid.UUID) error {
	return a.Db.RunInTx(ctx, func(q *sql.Queries) error {
		result, err := q.SiloById(ctx, id)
		if err != nil {
			return err
		}
		storage := a.FindStorageBackend(result.Storage)
		if storage == nil {
			return errors.New("storage backend not found for " + id.String())
		}

		silo := core.NewSilo(a.Db, result.Name, result.Owner, result.ID, storage)
		resource, err := silo.ResourceByPath(ctx, "/")
		if err != nil {
			return err
		}
		if err := resource.DeleteRecursive(ctx, true); err != nil {
			return err
		}

		return q.DeleteSilo(ctx, id)
	})
}
