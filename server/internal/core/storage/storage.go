package storage

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"hash"
	"io"
	"os"
	"path"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

type Storage struct {
	backends       map[string]Backend
	defaultBackend Backend
}

var s Storage
var Cfg Config

func Get() Storage {
	if s.defaultBackend == nil {
		if storage, err := create(Cfg.Location); err != nil {
			logrus.Fatal(err)
		} else {
			s = storage
		}
	}
	return s
}

func create(storageLocation string) (Storage, error) {
	if err := os.Chmod(storageLocation, 0700); err != nil {
		return Storage{}, err
	}
	if backends, err := restoreBackends(); err != nil {
		return Storage{}, err
	} else if defaultBackend, err := createLocalBackend(map[string]string{"root": path.Join(storageLocation, "default")}, true); err != nil {
		return Storage{}, err
	} else {
		return Storage{
			backends:       backends,
			defaultBackend: defaultBackend,
		}, nil
	}
}

func (s Storage) OpenRead(id uuid.UUID, start, length int) (io.ReadCloser, error) {
	if backend, err := s.findStorageBackend(id); err != nil {
		return nil, err
	} else {
		return backend.OpenRead(id, start, length)
	}
}

func (s Storage) OpenWrite(id uuid.UUID, h func() hash.Hash, callback func(int, string, string) error) (io.WriteCloser, error) {
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

type ContentsCopy struct {
	SrcVersion   uuid.UUID
	DestResource uuid.UUID
	Size         int64
	MimeType     string
	SHA256       string
}

func (s Storage) CopyContents(params ContentsCopy) (uuid.UUID, error) {
	in, err := s.OpenRead(params.SrcVersion, 0, -1)
	if err != nil {
		return uuid.Nil, errors.New("Unable to open " + params.SrcVersion.String() + ": " + err.Error())
	}
	defer in.Close()
	id, _ := uuid.NewV7()

	out, err := s.OpenWrite(id, nil, nil)
	if err != nil {
		return uuid.Nil, errors.New("Unable to open " + id.String() + ": " + err.Error())
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	return id, err

}

func (s Storage) Delete(id uuid.UUID) error {
	if backend, err := s.findStorageBackend(id); err != nil {
		return err
	} else {
		return backend.Delete(id)
	}
}

func (s Storage) DeleteAll(ids []uuid.UUID) []error {
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

func (s Storage) findStorageBackend(id uuid.UUID) (Backend, error) {
	// TODO: implement
	return s.defaultBackend, nil
}

func (s Storage) CreateBackend(db db.Handler, name string, driver Driver, params map[string]string) error {
	backend, err := driver.Create(params, true)
	if err != nil {
		return nil
	}
	const q = "INSERT INTO storage_backends(name, driver, params) VALUES ($1::TEXT, $2::TEXT, $3::JSONB)"
	p, err := json.Marshal(params)
	if err != nil {
		return err
	}
	if _, err := db.Exec(q, name, driver, p); err != nil {
		return err
	}
	s.backends[name] = backend
	return nil
}

func (s Storage) ListBackends() map[string]Backend {
	return s.backends
}

func restoreBackends() (map[string]Backend, error) {
	const q = "SELECT name, driver, params from storage_backends"
	if rows, err := db.Get(context.Background()).Query(q); err != nil {
		return nil, err
	} else if backends, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (namedBackend, error) {
		var name, driverName string
		var paramsJSON []byte
		if err := row.Scan(&name, &driverName, &paramsJSON); err != nil {
			return namedBackend{}, err
		}
		params := make(map[string]string)
		if err := json.Unmarshal(paramsJSON, &params); err != nil {
			return namedBackend{}, err
		} else if driver, err := FindDriver(driverName); err != nil {
			return namedBackend{}, err
		} else if backend, err := driver.Create(params, false); err != nil {
			return namedBackend{}, err
		} else {
			return namedBackend{name: name, backend: backend}, nil
		}
	}); err != nil {
		return nil, err
	} else {
		results := map[string]Backend{}
		for _, b := range backends {
			results[b.name] = b.backend
		}
		return results, nil
	}
}

type namedBackend struct {
	name    string
	backend Backend
}
