package storage

import (
	"context"
	"errors"

	"github.com/shroff/phylum/server/internal/sql"
)

type Manager struct {
	db       *sql.DbHandler
	backends map[string]Storage
}

func NewManager(db *sql.DbHandler) (*Manager, error) {
	backends, err := db.Queries().AllStorageBackends(context.Background())
	if err != nil {
		return nil, err
	}
	manager := &Manager{
		db:       db,
		backends: map[string]Storage{},
	}
	for _, b := range backends {
		store, err := openStorage(b.Driver, b.Params)
		if err != nil {
			return nil, err
		}
		manager.backends[b.Name] = store
	}
	return manager, err
}

func (m Manager) Create(name string, driver string, params map[string]string) error {
	storage, err := openStorage(driver, params)
	if err != nil {
		return nil
	}
	err = m.db.Queries().CreateStorageBackend(context.Background(), sql.CreateStorageBackendParams{
		Name:   name,
		Driver: driver,
		Params: params,
	})
	if err != nil {
		return err
	}
	m.backends[name] = storage
	return nil
}

func (m Manager) Find(name string) Storage {
	return m.backends[name]
}

func (m Manager) All() map[string]Storage {
	return m.backends
}

func openStorage(driver string, params map[string]string) (Storage, error) {
	switch driver {
	case "local":
		return newLocalStorage(params["root"])
	}
	return nil, errors.New("unrecognized storage driver: " + driver)
}

func ParamNames(driver string) ([]string, error) {
	switch driver {
	case "local":
		return []string{"root"}, nil
	}
	return nil, errors.New("unrecognized storage driver: " + driver)
}
