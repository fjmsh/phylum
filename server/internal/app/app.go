package app

import (
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
)

type App struct {
	Db       *db.DbHandler
	backends map[string]storage.Storage
}

var Default *App

func Initialize(db *db.DbHandler) error {
	backends, err := restoreStorageBackends(db)
	if err != nil {
		return err
	}

	Default = &App{
		Db:       db,
		backends: backends,
	}

	return nil
}

func (a App) Cleanup() {
	if a.Db != nil {
		a.Db.Close()
	}
}
