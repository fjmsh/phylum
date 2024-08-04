package app

import (
	"context"

	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/sql"
)

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
	} else if err = a.Db.Queries().CreateUser(ctx, sql.CreateUserParams{Username: username, DisplayName: displayName, PasswordHash: hash}); err != nil {
		return err
	}
	return nil
}

func (a App) ListUsers(ctx context.Context) ([]User, error) {
	results, err := a.Db.Queries().ListUsers(ctx)
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

func (a App) FindUser(ctx context.Context, username string) (User, error) {
	result, err := a.Db.Queries().UserByUsername(ctx, username)
	if err != nil {
		return nil, err
	}
	return user{
		id:          result.ID,
		username:    result.Username,
		displayName: result.DisplayName,
	}, nil
}
