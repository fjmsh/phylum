package core

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/db"
)

var ErrUserNotFound = errors.New("user not found")

func (a App) CreateUser(ctx context.Context, username, displayName, password string, root *uuid.UUID) error {
	var rootID = a.Rootfs.RootID()
	if root != nil {
		rootID = *root
	}
	return a.db.WithTx(ctx, func(d *db.DbHandler) error {
		fs := a.Rootfs.WithDb(d)
		if hash, err := cryptutil.GenerateArgon2EncodedHash(password, cryptutil.DefaultArgon2Params()); err != nil {
			return err
		} else if u, err := d.CreateUser(ctx, db.CreateUserParams{
			Username:     username,
			DisplayName:  displayName,
			PasswordHash: hash,
			Root:         rootID,
			Home:         rootID,
		}); err != nil {
			return err
		} else if home, err := fs.ResourceByPath("/home"); err != nil {
			return err
		} else if userHome, err := fs.CreateMemberResource(home, uuid.New(), username, true); err != nil {
			return err
		} else if err := fs.UpdatePermissions(userHome, u.Username, PermissionReadWriteShare); err != nil {
			return err
		} else {
			return d.UpdateUserHome(ctx, db.UpdateUserHomeParams{Username: u.Username, Home: userHome.ID})
		}
	})
}

func (a App) ListUsers(ctx context.Context) ([]User, error) {
	results, err := a.db.ListUsers(ctx)
	if err != nil {
		return nil, err
	}
	users := make([]User, len(results))
	for i, r := range results {
		users[i] = User{
			Username:    r.Username,
			DisplayName: r.DisplayName,
			Root:        r.Root,
			Home:        r.Home,
		}
	}
	return users, nil
}

func (a App) UserByEmail(ctx context.Context, email string) (User, error) {
	result, err := a.db.UserByUsername(ctx, email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrUserNotFound
		}
		return User{}, err
	}
	return User{
		Username:    result.Username,
		DisplayName: result.DisplayName,
		Root:        result.Root,
		Home:        result.Home,
	}, nil
}

func (a App) UpdateUserRoot(ctx context.Context, user User, root uuid.UUID) error {
	return a.db.UpdateUserRoot(ctx, db.UpdateUserRootParams{Username: user.Username, Root: root})
}

func (a App) UpdateUserHome(ctx context.Context, user User, home uuid.UUID) error {
	return a.db.UpdateUserHome(ctx, db.UpdateUserHomeParams{Username: user.Username, Home: home})
}

func (a App) UpdateUserDisplayName(ctx context.Context, user User, displayName string) error {
	return a.db.UpdateUserDisplayName(ctx, db.UpdateUserDisplayNameParams{Username: user.Username, DisplayName: displayName})
}
