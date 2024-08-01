package app

import (
	"github.com/shroff/phylum/server/internal/app/core"
	"github.com/shroff/phylum/server/internal/db"
)

type App struct {
	Db       *db.DbHandler
	backends map[string]core.Storage
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
