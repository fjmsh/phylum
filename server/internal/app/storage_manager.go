package app

import (
	"context"

	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
)

func restoreStorageBackends(db *db.DbHandler) (map[string]storage.Storage, error) {
	backends, err := db.Queries().AllStorageBackends(context.Background())
	if err != nil {
		return nil, err
	}
	results := map[string]storage.Storage{}
	for _, b := range backends {
		store, err := storage.Open(b.Driver, b.Params)
		if err != nil {
			return nil, err
		}
		results[b.Name] = store
	}
	return results, nil
}

func (a App) CreateStorageBackend(name string, driver string, params map[string]string) error {
	storage, err := storage.Open(driver, params)
	if err != nil {
		return nil
	}
	err = a.Db.Queries().CreateStorageBackend(context.Background(), sql.CreateStorageBackendParams{
		Name:   name,
		Driver: driver,
		Params: params,
	})
	if err != nil {
		return err
	}
	a.backends[name] = storage
	return nil
}

func (a App) FindStorageBackend(name string) storage.Storage {
	return a.backends[name]
}

func (a App) ListStorageBackends() map[string]storage.Storage {
	return a.backends
}
