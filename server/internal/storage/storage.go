package storage

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/pubsub"
	"github.com/jackc/pgx/v5"
	"github.com/rs/zerolog"
)

const DefaultBackendName = "_"

var defaultBackend LocalBackend
var backends map[string]Backend
var storageRoot string
var tempDir string

type BackendConfig struct {
	Name   string            `json:"name"`
	Driver string            `json:"driver"`
	Params map[string]string `json:"params"`
}

func Initialize(db db.Handler, cfg Config, logger zerolog.Logger) error {
	storageRoot = cfg.Root

	if err := os.MkdirAll(storageRoot, 0o700); err != nil {
		return errors.New("failed to create storage root(" + storageRoot + "): " + err.Error())
	} else {
		if stat, err := os.Stat(storageRoot); err != nil {
			return errors.New("failed to stat storage root(" + storageRoot + "): " + err.Error())
		} else if stat.Mode()&0xfff != 0o700 {
			os.Chmod(cfg.Root, 0o700)
		}
	}

	tempDir = cfg.Temp
	if !filepath.IsAbs(tempDir) {
		tempDir = filepath.Join(storageRoot, tempDir)
		if err := os.RemoveAll(tempDir); err != nil {
			return errors.New("failed to clear temp directory: " + err.Error())
		}
		if err := os.MkdirAll(tempDir, 0700); err != nil {
			return errors.New("failed to create temp directory: " + err.Error())
		}
	}

	if restoredBackends, err := restoreBackends(db); err != nil {
		return errors.New("failed to restore backends: " + err.Error())
	} else if b, err := createLocalBackend(DefaultBackendName, map[string]string{"root": "default"}); err != nil {
		return errors.New("failed to create default backend: " + err.Error())
	} else {
		backends = restoredBackends
		defaultBackend = b
	}

	go processBackendUpdates(logger)
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

func processBackendUpdates(logger zerolog.Logger) {
	sub := pubsub.Get().Listen("backend_updates", 5, true)
	for {
		p := <-sub.NotificationC()
		var c BackendConfig
		if err := json.Unmarshal([]byte(p), &c); err != nil {
			logger.Warn().Err(err).Msg("failed to unmarshal backend config")
		} else if b, err := c.open(); err != nil {
			logger.Warn().Err(err).Msg("failed to open backend")
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
