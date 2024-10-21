package app

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/shroff/phylum/server/internal/core/user"
)

type App interface {
	RunInTx(ctx context.Context, fn func(*db.DbHandler) error) error
	OpenFileSystem(ctx context.Context, u user.User) fs.FileSystem
	OpenUserManager(ctx context.Context) user.Manager
}

type app struct {
	db *db.DbHandler
	cs storage.Storage
}

func Create(ctx context.Context, db *db.DbHandler, cs storage.Storage) (App, error) {
	app := app{
		db: db,
		cs: cs,
	}
	userManager := user.CreateManager(ctx, db)
	if _, err := userManager.UserByEmail(user.DefaultUserUsername); err != nil {
		if errors.Is(err, user.ErrNotFound) {
			_, err = app.populateData(ctx)
		}
		if err != nil {
			return nil, err
		}
	}

	return app, nil
}

func (a app) RunInTx(ctx context.Context, fn func(*db.DbHandler) error) error {
	return a.db.WithTx(ctx, fn)
}

func (a app) OpenFileSystem(ctx context.Context, u user.User) fs.FileSystem {
	return fs.OpenFileSystem(a.db, ctx, a.cs, u.Username, u.Root)
}

func (a app) OpenUserManager(ctx context.Context) user.Manager {
	return user.CreateManager(ctx, a.db)
}

func (a app) populateData(ctx context.Context) (u user.User, e error) {
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
			Name:   user.DefaultUserUsername,
			Dir:    true,
		})
		if err != nil {
			return err
		}

		// Create phylum user
		u, err := dbh.CreateUser(ctx, db.CreateUserParams{
			Username:     user.DefaultUserUsername,
			DisplayName:  user.DefaultUserDisplayName,
			PasswordHash: "CANNOT LOG IN",
			Root:         root.ID,
			Home:         userHome.ID,
		})
		if err != nil {
			return err
		}
		user := user.User{
			Username:    u.Username,
			DisplayName: u.DisplayName,
			Root:        u.Root,
			Home:        u.Home,
		}

		_, err = dbh.UpdateUserPermissionsForResource(ctx, db.UpdateUserPermissionsForResourceParams{
			ResourceID: root.ID,
			Username:   user.Username,
			Permission: fs.PermissionReadWriteShare,
		})
		return err
	})
	return
}
