package storage

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

var Cfg Config
var defaultBackend LocalBackend
var backends map[string]Backend

type BackendConfig struct {
	Name   string            `json:"name"`
	Driver string            `json:"driver"`
	Params map[string]string `json:"params"`
}

func Initialize(db db.Handler) error {
	if err := os.Chmod(Cfg.Location, 0700); err != nil {
		return errors.New("failed to set permissions: " + err.Error())
	}
	if restoredBackends, err := restoreBackends(); err != nil {
		return errors.New("failed to restore backends: " + err.Error())
	} else if b, err := createLocalBackend(map[string]string{"root": path.Join(Cfg.Location, "default")}); err != nil {
		return errors.New("failed to create default backend: " + err.Error())
	} else {
		restoredBackends[""] = b
		backends = restoredBackends
		defaultBackend = b
	}

	go processBackendUpdates(db)
	return nil
}

func DefaultBackend() LocalBackend {
	return defaultBackend
}

func GetBackend(name string) Backend {
	return backends[name]
}

func ListBackends() map[string]Backend {
	return backends
}

func InsertBackend(db db.Handler, name string, driver Driver, params map[string]string) error {
	backend, err := driver.Create(params)
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
	backends[name] = backend
	return nil
}

func restoreBackends() (map[string]Backend, error) {
	const q = "SELECT name, driver, params from storage_backends"
	if rows, err := db.Get(context.Background()).Query(q); err != nil {
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
		return driver.Create(c.Params)
	}
}
