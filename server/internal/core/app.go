package core

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
)

const defaultUserEmail = "admin@phylum"

type App struct {
	Debug  bool
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
	u, err := a.db.UserByEmail(ctx, defaultUserEmail)

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
			Name:   defaultUserEmail,
			Dir:    true,
		})
		if err != nil {
			return err
		}

		// Create phylum user
		user, err = dbh.CreateUser(ctx, db.CreateUserParams{
			Email:        defaultUserEmail,
			DisplayName:  "Phylum",
			PasswordHash: "",
			Root:         root.ID,
			Home:         userHome.ID,
		})
		if err != nil {
			return err
		}

		return dbh.UpdatePermissionsForResource(ctx, db.UpdatePermissionsForResourceParams{
			ResourceID: root.ID,
			UserID:     user.ID,
			Permission: PermissionReadWriteShare,
		})
	})
	return
}

func (a App) OpenFileSystem(ctx context.Context, user User) (FileSystem, error) {
	return OpenFileSystem(a.db, ctx, a.cs, user.ID, user.Root)
}
