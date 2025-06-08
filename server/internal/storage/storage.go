package storage

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/sirupsen/logrus"
)

var Cfg Config

const DefaultBackendName = "_"

var defaultBackend LocalBackend
var backends map[string]Backend
var tempDir string

type BackendConfig struct {
	Name   string            `json:"name"`
	Driver string            `json:"driver"`
	Params map[string]string `json:"params"`
}

func Initialize(db db.Handler) error {
	if err := os.MkdirAll(Cfg.Root, 0700); err != nil {
		return errors.New("failed to create storage root(" + Cfg.Root + "): " + err.Error())
	} else {
		if stat, err := os.Stat(Cfg.Root); err != nil {
			return errors.New("failed to stat storage root(" + Cfg.Root + "): " + err.Error())
		} else if stat.Mode()&0xfff != 0700 {
			return errors.New("storage root does not have correct permissions (0700): " + fmt.Sprintf("%o", stat.Mode()&0xfff))
		}

	}

	tempDir = Cfg.Temp
	if !strings.HasPrefix(Cfg.Temp, string(os.PathSeparator)) {
		tempDir = filepath.Join(Cfg.Root, tempDir)
	}
	if err := os.RemoveAll(tempDir); err != nil {
		return errors.New("failed to clear temp directory: " + err.Error())
	}
	if err := os.MkdirAll(tempDir, 0700); err != nil {
		return errors.New("failed to create temp directory: " + err.Error())
	}

	if restoredBackends, err := restoreBackends(db); err != nil {
		return errors.New("failed to restore backends: " + err.Error())
	} else if b, err := createLocalBackend(DefaultBackendName, map[string]string{"root": "default"}); err != nil {
		return errors.New("failed to create default backend: " + err.Error())
	} else {
		backends = restoredBackends
		defaultBackend = b
	}

	go processBackendUpdates(db)
	return nil
}

func DefaultBackend() LocalBackend {
	return defaultBackend
}

func GetBackend(name string) (Backend, error) {
	if name == DefaultBackendName {
		return defaultBackend, nil
	}
	if b, ok := backends[name]; !ok {
		return nil, errors.New("no storage backend named \"" + name + "\"")
	} else {
		return b, nil
	}
}

func ListBackends() map[string]Backend {
	return backends
}

func InsertBackend(db db.Handler, name string, driver Driver, params map[string]string) error {
	backend, err := driver.Create(name, params)
	if err != nil {
		return nil
	}
	const q = "INSERT INTO storage_backends(name, driver, params) VALUES ($1::TEXT, $2::TEXT, $3::JSONB)"
	p, err := json.Marshal(params)
	if err != nil {
		return err
	}
	if _, err := db.Exec(q, name, driver.Name, p); err != nil {
		return err
	}
	backends[name] = backend
	return nil
}

func restoreBackends(db db.Handler) (map[string]Backend, error) {
	const q = "SELECT name, driver, params from storage_backends"
	if rows, err := db.Query(q); err != nil {
		return nil, err
	} else if backends, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (BackendConfig, error) {
		var c BackendConfig
		var paramsJSON []byte
		if err := row.Scan(&c.Name, &c.Driver, &paramsJSON); err != nil {
			return BackendConfig{}, errors.New("failed to scan backend config: " + err.Error())
		}

		c.Params = make(map[string]string)
		if err := json.Unmarshal(paramsJSON, &c.Params); err != nil {
			return BackendConfig{}, errors.New("failed to unmarshal backend params: " + err.Error())
		}
		return c, nil
	}); err != nil {
		return nil, err
	} else {
		results := map[string]Backend{}
		for _, c := range backends {
			if b, err := c.open(); err != nil {
				return nil, errors.New("failed to open backend: " + err.Error())
			} else {
				results[c.Name] = b
			}
		}
		return results, nil
	}
}

func processBackendUpdates(db db.Handler) {
	sub := db.Notifier().Listen("backend_updates")
	for {
		p := <-sub.NotificationC()
		var c BackendConfig
		if err := json.Unmarshal([]byte(p), &c); err != nil {
			logrus.Warn("failed to unmarshal backend config: " + err.Error())
		} else if b, err := c.open(); err != nil {
			logrus.Warn("failed to open backend: " + err.Error())
		} else {
			backends[c.Name] = b
		}
	}
}

func (c BackendConfig) open() (Backend, error) {
	if driver, err := FindDriver(c.Driver); err != nil {
		return nil, err
	} else {
		return driver.Create(c.Name, c.Params)
	}
}
