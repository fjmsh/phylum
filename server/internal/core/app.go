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

func Create(db *db.DbHandler, cs storage.Storage, debug bool) error {
	Default = &App{
		Debug: debug,
		db:    db,
		cs:    cs,
	}

	return Default.setupAppData()
}

func (a App) setupAppData() error {
	ctx := context.Background()

	_, err := a.db.Queries().UserByUsername(context.Background(), defaultUserName)
	// Root user found. We can assume that setup has been done before
	if !errors.Is(err, pgx.ErrNoRows) {
		return err
	}
	return a.db.RunInTx(ctx, func(tx pgx.Tx) error {
		q := a.db.Queries().WithTx(tx)
		// Create phylum user
		user, err := q.CreateUser(ctx, db.CreateUserParams{
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

		// Create personal home folder
		phylumHome, err := q.CreateResource(ctx, db.CreateResourceParams{
			ID:     uuid.New(),
			Owner:  user.ID,
			Parent: &home.ID,
			Name:   user.Username,
			Dir:    true,
		})
		if err != nil {
			return err
		}

		if err := q.UpdateUserDirs(ctx, db.UpdateUserDirsParams{ID: user.ID, Root: root.ID, Home: phylumHome.ID}); err != nil {
			return err
		}
		_, err = tx.Exec(ctx, "SET CONSTRAINTS user_root, user_home IMMEDIATE;")
		if err != nil {
			return err
		}

		_, err = tx.Exec(ctx, "ALTER TABLE users ALTER CONSTRAINT user_root NOT DEFERRABLE;"+
			"ALTER TABLE users ALTER CONSTRAINT user_home NOT DEFERRABLE;",
		)

		return err
	})
}

func (a App) OpenFileSystem(ctx context.Context, user User) (FileSystem, error) {
	return OpenFileSystem(a.db, ctx, a.cs, user)
}
