package core

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
)

const defaultUserUsername = "phylum"
const defaultUserDisplayName = "Phylum"

type App struct {
	Rootfs FileSystem
	db     *db.DbHandler
	cs     storage.Storage
}

var Default *App

func Create(ctx context.Context, db *db.DbHandler, cs storage.Storage) error {
	Default = &App{
		db: db,
		cs: cs,
	}

	return Default.setupAppData(ctx)
}

func (a *App) setupAppData(ctx context.Context) error {
	u, err := a.UserByEmail(ctx, defaultUserUsername)

	if errors.Is(err, ErrUserNotFound) {
		u, err = a.populateData(ctx)
	}
	if err == nil {
		a.Rootfs = OpenFileSystem(a.db, ctx, a.cs, u.Username, u.Root)
	}
	return err
}

func (a *App) populateData(ctx context.Context) (user User, e error) {
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
		user = User{
			Username:    u.Username,
			DisplayName: u.DisplayName,
			Root:        u.Root,
			Home:        u.Home,
		}

		return dbh.UpdateUserPermissionsForResource(ctx, db.UpdateUserPermissionsForResourceParams{
			ResourceID: root.ID,
			Username:   user.Username,
			Permission: PermissionReadWriteShare,
		})
	})
	return
}

func (a App) OpenFileSystem(ctx context.Context, user User) FileSystem {
	return OpenFileSystem(a.db, ctx, a.cs, user.Username, user.Root)
}

func (a App) GetSharedResources(ctx context.Context, user User) (result []Resource, err error) {
	res, err := a.db.Queries.SharedResources(ctx, db.SharedResourcesParams{Username: user.Username, UserHome: user.Home})
	if err != nil {
		return
	}

	result = make([]Resource, len(res))
	for i, r := range res {
		var deleted *time.Time
		if r.Deleted.Valid {
			deleted = &r.Deleted.Time
		}
		result[i] = Resource{
			ID:            r.ID,
			ParentID:      r.Parent,
			Name:          r.Name,
			Dir:           r.Dir,
			Created:       r.Created.Time,
			Modified:      r.Modified.Time,
			Deleted:       deleted,
			ContentSize:   r.ContentSize,
			ContentType:   r.ContentType,
			ContentSHA256: r.ContentSha256,
			Permissions:   string(r.Permissions),
		}
	}
	return
}
