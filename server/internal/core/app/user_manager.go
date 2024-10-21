package app

import (
	"context"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/errors"
)

var ErrUserNotFound = errors.NewError(http.StatusNotFound, "user_not_found", "no such user")
var ErrUserExists = errors.NewError(http.StatusNotFound, "user_already_exists", "user already exists")

func (a App) CreateUser(ctx context.Context, username, displayName, password string, root uuid.UUID) (User, error) {
	if hash, err := generateArgon2EncodedHash(password, defaultArgon2Params()); err != nil {
		return User{}, err
	} else if u, err := a.db.CreateUser(ctx, db.CreateUserParams{
		Username:     username,
		DisplayName:  displayName,
		PasswordHash: hash,
		Root:         root,
		Home:         root,
	}); err != nil {
		if strings.Contains(err.Error(), "users_pkey") {
			err = ErrUserExists
		}
		return User{}, err
	} else {
		return User{
			Username:    u.Username,
			DisplayName: u.DisplayName,
			Root:        u.Root,
			Home:        u.Home,
		}, nil
	}

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
