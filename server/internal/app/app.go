package app

import (
	"context"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/app/core"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
)

type App struct {
	Debug   bool
	adminfs core.FileSystem
	db      *db.DbHandler
	cs      storage.Storage
}

var Default *App

func Initialize(db *db.DbHandler, cs storage.Storage, debug bool) error {
	Default = &App{
		Debug: debug,
		db:    db,
		cs:    cs,
	}

	if root, err := Default.UserByUsername(context.Background(), "phylum"); err != nil {
		return err
	} else if fs, err := Default.OpenFileSystem(context.Background(), root.ID()); err != nil {
		return err
	} else {
		Default.adminfs = fs
		if _, err := fs.ResourceByPath("/home"); err != nil {
			_, err := fs.CreateMemberResource(fs.Root(), uuid.New(), "home", true)
			return err
		}
	}

	return nil
}

func (a App) OpenFileSystem(ctx context.Context, user int32) (core.FileSystem, error) {
	return core.OpenFileSystem(a.db, ctx, a.cs, nil, user)
}
