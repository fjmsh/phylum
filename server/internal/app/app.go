package app

import (
	"context"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/app/core"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/sql"
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

	if _, err := db.Queries().CreateResource(context.Background(), sql.CreateResourceParams{
		ID:     uuid.UUID{},
		Parent: uuid.UUID{},
		Name:   "root",
		Dir:    true,
	}); err != nil {
		return err
	}

	Default = &App{
		Debug:    debug,
		Db:       db,
		backends: backends,
	}

	return nil
}

func (a App) OpenFileSystem(ctx context.Context, user int32) (core.FileSystem, error) {
	return core.OpenFileSystem(a.Db, ctx, nil, user)
}
