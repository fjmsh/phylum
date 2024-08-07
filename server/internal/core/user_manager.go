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
	var rootID = a.Rootfs.Root().ID()
	if root != nil {
		rootID = *root
	}
	return a.db.WithTx(ctx, func(q *db.Queries) error {
		if hash, err := cryptutil.GenerateArgon2EncodedHash(password, cryptutil.DefaultArgon2Params()); err != nil {
			return err
		} else if u, err := q.CreateUser(ctx, db.CreateUserParams{
			Username:     username,
			DisplayName:  displayName,
			PasswordHash: hash,
			Root:         rootID,
			Home:         rootID,
		}); err != nil {
			return err
		} else if home, err := a.Rootfs.ResourceByPath("/home"); err != nil {
			return err
		} else if userHome, err := a.Rootfs.CreateMemberResource(home, uuid.New(), username, true); err != nil {
			return err
		} else if err := a.Rootfs.UpdateOwner(userHome, u.ID); err != nil {
			return err
		} else {
			return q.UpdateUserHome(ctx, db.UpdateUserHomeParams{ID: u.ID, Home: userHome.ID()})
		}
	})
}

func (a App) ListUsers(ctx context.Context) ([]User, error) {
	results, err := a.db.Queries().ListUsers(ctx)
	if err != nil {
		return nil, err
	}
	users := make([]User, len(results))
	for i, r := range results {
		users[i] = user{
			id:          r.ID,
			username:    r.Username,
			displayName: r.DisplayName,
			root:        r.Root,
			home:        r.Home,
		}
	}
	return users, nil
}

func (a App) UserByUsername(ctx context.Context, username string) (User, error) {
	result, err := a.db.Queries().UserByUsername(ctx, username)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrUserNotFound
		}
		return nil, err
	}
	return user{
		id:          result.ID,
		username:    result.Username,
		displayName: result.DisplayName,
		root:        result.Root,
		home:        result.Home,
	}, nil
}

func (a App) UserByID(ctx context.Context, userID int32) (User, error) {
	result, err := a.db.Queries().UserByID(ctx, userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrUserNotFound
		}
		return nil, err
	}
	return user{
		id:          result.ID,
		username:    result.Username,
		displayName: result.DisplayName,
		root:        result.Root,
		home:        result.Home,
	}, nil
}

func (a App) UpdateUserRoot(ctx context.Context, user User, root uuid.UUID) error {
	return a.db.Queries().UpdateUserRoot(ctx, db.UpdateUserRootParams{ID: user.ID(), Root: root})
}

func (a App) UpdateUserHome(ctx context.Context, user User, home uuid.UUID) error {
	return a.db.Queries().UpdateUserHome(ctx, db.UpdateUserHomeParams{ID: user.ID(), Home: home})
}

func (a App) UpdateUserDisplayName(ctx context.Context, user User, displayName string) error {
	return a.db.Queries().UpdateUserDisplayName(ctx, db.UpdateUserDisplayNameParams{ID: user.ID(), DisplayName: displayName})
}
