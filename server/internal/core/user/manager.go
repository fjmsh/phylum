package user

import (
	"context"
	"net/http"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/errors"
)

type Manager interface {
	WithDb(db *db.DbHandler) Manager

	// create.go
	CreateUser(username, displayName, password string, root uuid.UUID) (User, error)

	ListUsers() ([]User, error)
	UserByEmail(email string) (User, error)

	// update.go
	UpdateUserRoot(user User, root uuid.UUID) error
	UpdateUserHome(user User, home uuid.UUID) error
	UpdateUserDisplayName(user User, displayName string) error

	// auth.go
	VerifyUserPassword(email, password string) (User, error)
	CreateAccessToken(username string) (string, error)
	ReadAccessToken(accessToken string) (User, error)
}

type manager struct {
	db  *db.DbHandler
	ctx context.Context
}

func CreateManager(ctx context.Context, db *db.DbHandler) Manager {
	return &manager{
		ctx: ctx,
		db:  db,
	}
}

func (m manager) WithDb(db *db.DbHandler) Manager {
	return m.withDb(db)
}

func (m manager) withDb(db *db.DbHandler) manager {
	return manager{
		ctx: m.ctx,
		db:  db,
	}
}

var ErrNotFound = errors.NewError(http.StatusNotFound, "user_not_found", "no such user")

func (m manager) ListUsers() ([]User, error) {
	results, err := m.db.ListUsers(m.ctx)
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

func (m manager) UserByEmail(email string) (User, error) {
	result, err := m.db.UserByUsername(m.ctx, email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrNotFound
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
