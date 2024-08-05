package app

import (
	"context"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/app/core"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
)

type App struct {
	Debug       bool
	Db          *db.DbHandler
	Cs          storage.Storage
	adminUserID int32
}

var Default *App

func Initialize(db *db.DbHandler, contentDir string, debug bool) error {
	var adminUserID int32
	if u, err := db.Queries().UserByUsername(context.Background(), "root"); err != nil {
		return err
	} else {
		adminUserID = u.ID
	}

	if _, err := db.Queries().ResourceById(context.Background(), uuid.UUID{}); err != nil {
		return err
	}

	if cs, err := storage.Open(db, contentDir); err != nil {
		return err
	} else {
		Default = &App{
			Debug:       debug,
			Db:          db,
			Cs:          cs,
			adminUserID: adminUserID,
		}
	}

	return nil
}

func (a App) OpenFileSystem(ctx context.Context, user int32) (core.FileSystem, error) {
	if user <= 0 {
		user = a.adminUserID
	}
	return core.OpenFileSystem(a.Db, ctx, a.Cs, nil, user)
}
