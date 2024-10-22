package storage

import (
	"context"
	"encoding/hex"
	"errors"
	"hash"
	"io"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

type Storage interface {
	CreateBackend(ctx context.Context, name string, driver string, params map[string]string) error
	ListBackends() map[string]Backend
	OpenRead(id uuid.UUID, start, length int64) (io.ReadCloser, error)
	OpenWrite(id uuid.UUID, h func() hash.Hash, callback func(int, string, string) error) (io.WriteCloser, error)
	CopyContents(src, dest uuid.UUID) error
	Delete(id uuid.UUID) error
	DeleteAll(deleted []db.DeleteRecursiveRow) []error
}

type storage struct {
	db             *db.DbHandler
	backends       map[string]Backend
	defaultBackend Backend
}

var s Storage
var DefaultStorageDir string

func Get() Storage {
	if s == nil {
		if storage, err := create(context.Background(), db.Get(), DefaultStorageDir); err != nil {
			logrus.Fatal(err)
		} else {
			s = storage
		}
	}
	return s
}

func create(ctx context.Context, db *db.DbHandler, defaultStorageDir string) (Storage, error) {
	if backends, err := restoreBackends(db, ctx); err != nil {
		return nil, err
	} else if defaultBackend, err := newLocalStorage("<default>", defaultStorageDir); err != nil {
		return nil, err
	} else {
		return storage{
			db:             db,
			backends:       backends,
			defaultBackend: defaultBackend,
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
func (s storage) OpenWrite(id uuid.UUID, h func() hash.Hash, callback func(int, string, string) error) (io.WriteCloser, error) {
	if backend, err := s.findStorageBackend(id); err != nil {
		return nil, err
	} else if out, err := backend.OpenWrite(id); err != nil {
		return nil, err
	} else if callback == nil {
		return out, nil
	} else {
		return &hasher{dest: out, sum: h(), contents: make([]byte, 0, 10*1024), closeCallback: func(len int, sum hash.Hash, mime string) error {
			etag := hex.EncodeToString(sum.Sum(nil))
			return callback(len, etag, mime)
		}}, nil
	}
}

func (s storage) CopyContents(src, dest uuid.UUID) error {
	in, err := s.OpenRead(src, 0, -1)
	if err != nil {
		return errors.New("Unable to open " + src.String() + ": " + err.Error())
	}
	defer in.Close()
	out, err := s.OpenWrite(dest, nil, nil)
	if err != nil {
		return errors.New("Unable to open " + dest.String() + ": " + err.Error())
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	return err

}

func (s storage) Delete(id uuid.UUID) error {
	if backend, err := s.findStorageBackend(id); err != nil {
		return err
	} else {
		return backend.Delete(id)
	}
}

func (s storage) DeleteAll(deleted []db.DeleteRecursiveRow) []error {
	// TODO: Batch delete
	var errs []error
	for _, d := range deleted {
		if !d.Dir {
			err := s.Delete(d.ID)
			if err != nil {
				errs = append(errs, err)
			}
		}
	}
	return errs
}

func (s *storage) findStorageBackend(id uuid.UUID) (Backend, error) {
	// TODO: implement
	return s.defaultBackend, nil
}

func (s storage) CreateBackend(ctx context.Context, name string, driver string, params map[string]string) error {
	backend, err := openBackend(name, driver, params)
	if err != nil {
		return nil
	}
	err = s.db.CreateStorageBackend(ctx, db.CreateStorageBackendParams{
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

func restoreBackends(db *db.DbHandler, ctx context.Context) (map[string]Backend, error) {
	backends, err := db.AllStorageBackends(ctx)
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
