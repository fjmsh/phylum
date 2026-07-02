package storage

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

const DefaultBackendName = "_"

var defaultBackend LocalBackend
var backends map[string]Backend = make(map[string]Backend)
var mountPoints map[uuid.UUID]string = make(map[uuid.UUID]string)
var Root string
var tempDir string

func Initialize(cfg Config, logger zerolog.Logger) error {
	Root = cfg.Root

	if err := os.MkdirAll(Root, 0o700); err != nil {
		return errors.New("failed to create storage root(" + Root + "): " + err.Error())
	} else {
		if stat, err := os.Stat(Root); err != nil {
			return errors.New("failed to stat storage root(" + Root + "): " + err.Error())
		} else if stat.Mode()&0xfff != 0o700 {
			os.Chmod(cfg.Root, 0o700)
		}
	}

	tempDir = cfg.Temp
	if !filepath.IsAbs(tempDir) {
		tempDir = filepath.Join(Root, tempDir)
		if err := os.RemoveAll(tempDir); err != nil {
			return errors.New("failed to clear temp directory: " + err.Error())
		}
		if err := os.MkdirAll(tempDir, 0700); err != nil {
			return errors.New("failed to create temp directory: " + err.Error())
		}
	}

	if restoredBackends, err := restoreBackends(cfg.Mounts); err != nil {
		return errors.New("failed to restore backends: " + err.Error())
	} else if b, err := createLocalBackend(DefaultBackendName, map[string]string{"root": "default"}); err != nil {
		return errors.New("failed to create default backend: " + err.Error())
	} else {
		backends = restoredBackends
		defaultBackend = b
	}

	return nil
}

func DefaultBackend() LocalBackend {
	return defaultBackend
}

func GetBackendByName(name string) (Backend, error) {
	if name == DefaultBackendName {
		return defaultBackend, nil
	}
	if b, ok := backends[name]; !ok {
		return nil, errors.New("no storage backend named \"" + name + "\"")
	} else {
		return b, nil
	}
}

func GetBackendByMountPoint(id uuid.UUID) (Backend, error) {
	if name, ok := mountPoints[id]; !ok {
		return nil, nil
	} else {
		return GetBackendByName(name)
	}
}

func ListBackends() map[string]Backend {
	return backends
}

func InsertBackend(d db.Handler, name string, driver Driver, params map[string]string) error {
	p, err := json.Marshal(params)
	if err != nil {
		return err
	}
	const q = "INSERT INTO storage_backends(name, driver, params) VALUES ($1::TEXT, $2::TEXT, $3::JSONB)"

	if err := d.RunInTx(func(tx db.TxHandler) error {
		_, err := tx.Exec(q, name, driver.Name, p)
		if err != nil {
			return err
		}

		backend, err := driver.Create(name, params)
		if err != nil {
			return err
		}
		backends[name] = backend

		return nil
	}); err != nil {
		return err
	}

	return nil
}

func restoreBackends(mounts map[string]MountConfig) (map[string]Backend, error) {
	backends := map[string]Backend{}
	for name, m := range mounts {
		for _, mp := range m.MountPoints {
			if id, err := uuid.Parse(mp); err != nil {
				return nil, fmt.Errorf("failed to parse mount point `%s` for `%s`: %s", mp, name, err.Error())
			} else if backend, err := m.open(name); err != nil {
				return nil, fmt.Errorf("failed to open backend `%s`: %s", name, err.Error())
			} else {
				backends[name] = backend
				mountPoints[id] = name
			}
		}
	}
	return backends, nil
}

func (c MountConfig) open(name string) (Backend, error) {
	if driver, err := FindDriver(c.Driver); err != nil {
		return nil, err
	} else {
		return driver.Create(name, c.Params)
	}
}
