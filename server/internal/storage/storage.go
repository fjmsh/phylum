package storage

import (
	"context"
	"errors"
	"io"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/sql"
)

type Storage interface {
	CreateBackend(name string, driver string, params map[string]string) error
	ListBackends() map[string]Backend
	OpenRead(id uuid.UUID, start, length int64) (io.ReadCloser, error)
	OpenWrite(id uuid.UUID, callback func(int, string) error) (io.WriteCloser, error)
	Delete(rows []sql.HardDeleteRecursiveRow) []error
}

type storage struct {
	db             *db.DbHandler
	backends       map[string]Backend
	defaultBackend Backend
}

func Open(db *db.DbHandler, contentDir string) (Storage, error) {
	if backends, err := restoreBackends(db); err != nil {
		return nil, err
	} else {
		return storage{
			db:             db,
			backends:       backends,
			defaultBackend: localStorage{name: "<default>", root: contentDir},
		}, nil
	}
}

func (s storage) OpenRead(id uuid.UUID, start, length int64) (io.ReadCloser, error) {
	if backend, err := s.findStorageBackend(id); err != nil {
		return nil, err
	} else {
		return backend.OpenRead(id, start, length)
	}
}
func (s storage) OpenWrite(id uuid.UUID, callback func(int, string) error) (io.WriteCloser, error) {
	if backend, err := s.findStorageBackend(id); err != nil {
		return nil, err
	} else {
		return backend.OpenWrite(id, callback)
	}
}
func (s storage) Delete(rows []sql.HardDeleteRecursiveRow) []error {
	// TODO: implement
	return nil

}

func (s *storage) findStorageBackend(id uuid.UUID) (Backend, error) {
	// TODO: implement
	return s.defaultBackend, nil
}

func (s storage) CreateBackend(name string, driver string, params map[string]string) error {
	backend, err := openBackend(name, driver, params)
	if err != nil {
		return nil
	}
	err = s.db.Queries().CreateStorageBackend(context.Background(), sql.CreateStorageBackendParams{
		Name:   name,
		Driver: driver,
		Params: params,
	})
	if err != nil {
		return err
	}
	s.backends[name] = backend
	return nil
}

func (s storage) ListBackends() map[string]Backend {
	return s.backends
}

func restoreBackends(db *db.DbHandler) (map[string]Backend, error) {
	backends, err := db.Queries().AllStorageBackends(context.Background())
	if err != nil {
		return nil, err
	}
	results := map[string]Backend{}
	for _, b := range backends {
		store, err := openBackend(b.Name, b.Driver, b.Params)
		if err != nil {
			return nil, err
		}
		results[b.Name] = store
	}
	return results, nil
}

func openBackend(name string, driver string, params map[string]string) (Backend, error) {
	switch driver {
	case "local":
		return newLocalStorage(name, params["root"])
	case "minio":
		return newMinioStorage(
			name,
			params["endpoint"],
			params["key_id"],
			params["access_key"],
			params["tmp"],
			params["bucket_name"],
			params["prefix"],
		)

	}
	return nil, errors.New("unrecognized storage driver: " + driver)
}

func ParamNames(driver string) ([]string, error) {
	switch driver {
	case "local":
		return []string{"root"}, nil
	case "minio":
		return []string{"endpoint", "key_id", "access_key", "tmp", "bucket_name", "prefix"}, nil
	}
	return nil, errors.New("unrecognized storage driver: " + driver)
}
