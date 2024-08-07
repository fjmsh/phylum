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
	Debug  bool
	rootfs FileSystem
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
	u, err := a.db.Queries().UserByUsername(ctx, defaultUserName)

	if errors.Is(err, pgx.ErrNoRows) {
		u, err = a.populateData(ctx)
	}
	if err == nil {
		if fs, err := OpenFileSystem(a.db, ctx, a.cs, u.ID, u.Root); err != nil {
			return err
		} else {
			a.rootfs = fs
		}
	}
	return err
}

func (a *App) populateData(ctx context.Context) (user db.User, e error) {
	e = a.db.RunInTx(ctx, func(tx pgx.Tx) error {
		q := a.db.Queries().WithTx(tx)
		// Create phylum user
		var err error
		user, err = q.CreateUser(ctx, db.CreateUserParams{
			Username:     defaultUserName,
			DisplayName:  "Phylum",
			PasswordHash: "",
		})
		if err != nil {
			return err
		}

		// Create root folder
		root, err := q.CreateResource(ctx, db.CreateResourceParams{
			ID:    uuid.New(),
			Owner: user.ID,
			Name:  "Phylum Root",
			Dir:   true,
		})
		if err != nil {
			return err
		}

		// Create home folder
		home, err := q.CreateResource(ctx, db.CreateResourceParams{
			ID:     uuid.New(),
			Owner:  user.ID,
			Parent: &root.ID,
			Name:   "home",
			Dir:    true,
		})
		if err != nil {
			return err
		}

		// Create user home folder
		userHome, err := q.CreateResource(ctx, db.CreateResourceParams{
			ID:     uuid.New(),
			Owner:  user.ID,
			Parent: &home.ID,
			Name:   user.Username,
			Dir:    true,
		})
		if err != nil {
			return err
		}

		if err := q.UpdateUserHome(ctx, db.UpdateUserHomeParams{ID: user.ID, Home: userHome.ID}); err != nil {
			return err
		}
		user.Root = root.ID
		user.Home = userHome.ID

		_, err = tx.Exec(ctx, "SET CONSTRAINTS user_root, user_home IMMEDIATE;")
		if err != nil {
			return err
		}

		_, err = tx.Exec(ctx, "ALTER TABLE users ALTER CONSTRAINT user_root NOT DEFERRABLE;"+
			"ALTER TABLE users ALTER CONSTRAINT user_home NOT DEFERRABLE;",
		)

		return err
	})
	return
}

func (a App) OpenFileSystem(ctx context.Context, user User) (FileSystem, error) {
	return OpenFileSystem(a.db, ctx, a.cs, user.ID(), user.Root())
}
