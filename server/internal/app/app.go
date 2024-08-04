package app

import (
	"github.com/shroff/phylum/server/internal/app/core"
	"github.com/shroff/phylum/server/internal/db"
)

type App struct {
	Debug    bool
	Db       *db.DbHandler
	backends map[string]core.Storage
}

var Default *App

func Initialize(db *db.DbHandler, debug bool) error {
	backends, err := restoreStorageBackends(db)
	if err != nil {
		return err
	}

	Default = &App{
		Debug:    debug,
		Db:       db,
		backends: backends,
	}

	return nil
}
