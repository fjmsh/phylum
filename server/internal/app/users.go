package app

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/db"
)

var ErrUserNotFound = errors.New("user not found")

type User interface {
	ID() int32
	Username() string
	DisplayName() string
}

type user struct {
	id          int32
	username    string
	displayName string
}

func (u user) ID() int32           { return u.id }
func (u user) Username() string    { return u.username }
func (u user) DisplayName() string { return u.displayName }

func (a App) CreateUser(ctx context.Context, username, displayName, password string) error {
	if hash, err := cryptutil.GenerateArgon2EncodedHash(password, cryptutil.DefaultArgon2Params()); err != nil {
		return err
	} else if u, err := a.db.Queries().CreateUser(ctx, db.CreateUserParams{Username: username, DisplayName: displayName, PasswordHash: hash}); err != nil {
		return err
	} else if home, err := a.adminfs.ResourceByPath("/home"); err != nil {
		return err
	} else if home, err := a.adminfs.CreateMemberResource(home, uuid.New(), username, true); err != nil {
		return err
	} else if err := a.adminfs.UpdateOwner(home, u.ID); err != nil {
		return err
	} else {
		homeID := home.ID()
		return a.db.Queries().UpdateUserHome(ctx, db.UpdateUserHomeParams{ID: u.ID, Home: &homeID})
	}
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
	}, nil
}
