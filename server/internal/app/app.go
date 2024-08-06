package app

import (
	"context"

	"github.com/shroff/phylum/server/internal/app/core"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
)

type App struct {
	Debug bool
	db    *db.DbHandler
	cs    storage.Storage
}

var Default *App

func Initialize(db *db.DbHandler, cs storage.Storage, debug bool) error {
	Default = &App{
		Debug: debug,
		db:    db,
		cs:    cs,
	}

	return nil
}

func (a App) OpenFileSystem(ctx context.Context, user int32) (core.FileSystem, error) {
	return core.OpenFileSystem(a.db, ctx, a.cs, nil, user)
}
