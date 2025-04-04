package storage

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"hash"
	"io"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

type Storage interface {
	CreateBackend(name string, driver string, params map[string]string) error
	ListBackends() map[string]Backend
	OpenRead(id uuid.UUID, start, length int) (io.ReadCloser, error)
	OpenWrite(id uuid.UUID, h func() hash.Hash, callback func(int, string, string) error) (io.WriteCloser, error)
	CopyContents(src, dest uuid.UUID) error
	Delete(id uuid.UUID) error
	DeleteAll(deleted []uuid.UUID) []error
}

type storage struct {
	db             db.Handler
	backends       map[string]Backend
	defaultBackend Backend
}

var s Storage
var DefaultStorageDir string

func Get() Storage {
	if s == nil {
		if storage, err := create(db.Get(), DefaultStorageDir); err != nil {
			logrus.Fatal(err)
		} else {
			s = storage
		}
	}
	return s
}

func create(db db.Handler, defaultStorageDir string) (Storage, error) {
	if backends, err := restoreBackends(db); err != nil {
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

func (s storage) OpenRead(id uuid.UUID, start, length int) (io.ReadCloser, error) {
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

func (s storage) DeleteAll(ids []uuid.UUID) []error {
	// TODO: Batch delete
	var errs []error
	for _, id := range ids {
		err := s.Delete(id)
		if err != nil {
			errs = append(errs, err)
		}
	}
	return errs
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
	const q = "INSERT INTO storage_backends(name, driver, params) VALUES ($1::TEXT, $2::TEXT, $3::JSONB)"
	p, err := json.Marshal(params)
	if err != nil {
		return err
	}
	if _, err := s.db.Exec(q, name, driver, p); err != nil {
		return err
	}
	s.backends[name] = backend
	return nil
}

func (s storage) ListBackends() map[string]Backend {
	return s.backends
}

func restoreBackends(db db.Handler) (map[string]Backend, error) {
	const q = "SELECT name, driver, params from storage_backends"
	if rows, err := db.Query(q); err != nil {
		return nil, err
	} else if backends, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (Backend, error) {
		var name, driver string
		var params []byte
		if err := row.Scan(&name, &driver, &params); err != nil {
			return nil, err
		}
		p := make(map[string]string)
		if err := json.Unmarshal(params, &p); err != nil {
			return nil, err
		}
		return openBackend(name, driver, p)
	}); err != nil {
		return nil, err
	} else {
		results := map[string]Backend{}
		for _, b := range backends {
			results[b.Name()] = b
		}
		return results, nil
	}
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
