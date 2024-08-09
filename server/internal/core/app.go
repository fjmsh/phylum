package core

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
)

const defaultUserName = "phylum"

type App struct {
	Debug bool
	// TODO: Fix su should have access to all files
	// but is currently subject to permissions which are baked in to ResourceByID and ResourceByPath
	Rootfs FileSystem
	db     *db.DbHandler
	cs     storage.Storage
}

var Default *App

func Create(ctx context.Context, db *db.DbHandler, cs storage.Storage, debug bool) error {
	Default = &App{
		Debug: debug,
		db:    db,
		cs:    cs,
	}

	return Default.setupAppData(ctx)
}

func (a *App) setupAppData(ctx context.Context) error {
	u, err := a.db.UserByUsername(ctx, defaultUserName)

	if errors.Is(err, pgx.ErrNoRows) {
		u, err = a.populateData(ctx)
	}
	if err == nil {
		if fs, err := OpenFileSystem(a.db, ctx, a.cs, u.ID, u.Root); err != nil {
			return err
		} else {
			a.Rootfs = fs
		}
	}
	return err
}

func (a *App) populateData(ctx context.Context) (user db.User, e error) {
	e = a.db.WithTx(ctx, func(dbh *db.DbHandler) error {
		var err error

		// Create root folder
		root, err := dbh.CreateResource(ctx, db.CreateResourceParams{
			ID:   uuid.New(),
			Name: "Phylum Root",
			Dir:  true,
		})
		if err != nil {
			return err
		}

		// Create home folder
		home, err := dbh.CreateResource(ctx, db.CreateResourceParams{
			ID:     uuid.New(),
			Parent: &root.ID,
			Name:   "home",
			Dir:    true,
		})
		if err != nil {
			return err
		}

		// Create user home folder
		userHome, err := dbh.CreateResource(ctx, db.CreateResourceParams{
			ID:     uuid.New(),
			Parent: &home.ID,
			Name:   user.Username,
			Dir:    true,
		})
		if err != nil {
			return err
		}

		// Create phylum user
		user, err = dbh.CreateUser(ctx, db.CreateUserParams{
			Username:     defaultUserName,
			DisplayName:  "Phylum",
			PasswordHash: "",
			Root:         root.ID,
			Home:         userHome.ID,
		})
		if err != nil {
			return err
		}

		return err
	})
	return
}

func (a App) OpenFileSystem(ctx context.Context, user User) (FileSystem, error) {
	return OpenFileSystem(a.db, ctx, a.cs, user.ID(), user.Root())
}
