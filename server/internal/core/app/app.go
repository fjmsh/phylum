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

const defaultUserUsername = "phylum"
const defaultUserDisplayName = "Phylum"

type App struct {
	Rootfs fs.FileSystem
	db     *db.DbHandler
	cs     storage.Storage
}

func Create(ctx context.Context, db *db.DbHandler, cs storage.Storage) (*App, error) {
	app := &App{
		db: db,
		cs: cs,
	}
	userManager := user.CreateManager(ctx, db)
	u, err := userManager.UserByEmail(defaultUserUsername)

	if errors.Is(err, user.ErrNotFound) {
		u, err = app.populateData(ctx)
	}
	if err != nil {
		return nil, err
	}
	app.Rootfs = fs.OpenFileSystem(db, ctx, cs, u.Username, u.Root)
	return app, nil
}

func (a App) WithDb(db *db.DbHandler) App {
	return App{
		db:     db,
		Rootfs: a.Rootfs.WithDb(db),
		cs:     a.cs.WithDb(db),
	}
}

func (a App) RunInTx(ctx context.Context, fn func(App) error) error {
	return a.db.WithTx(ctx, func(db *db.DbHandler) error {
		return fn(a.WithDb(db))
	})
}

func (a *App) populateData(ctx context.Context) (u user.User, e error) {
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
			Name:   defaultUserUsername,
			Dir:    true,
		})
		if err != nil {
			return err
		}

		// Create phylum user
		u, err := dbh.CreateUser(ctx, db.CreateUserParams{
			Username:     defaultUserUsername,
			DisplayName:  defaultUserDisplayName,
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

func (a App) OpenFileSystem(ctx context.Context, u user.User) fs.FileSystem {
	return fs.OpenFileSystem(a.db, ctx, a.cs, u.Username, u.Root)
}

func (a App) OpenUserManager(ctx context.Context) user.Manager {
	return user.CreateManager(ctx, a.db)
}
