package user

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/fs"
)

var Cfg Config

type User struct {
	ID          int32
	Email       string
	Name        string
	Home        pgtype.UUID
	Permissions Permission
}

func scanUser(row pgx.CollectableRow) (User, error) {
	var u User
	err := row.Scan(
		&u.ID,
		&u.Email,
		&u.Name,
		&u.Home,
		&u.Permissions,
	)
	return u, err
}

func (u User) OpenFileSystem(ctx context.Context) fs.FileSystem {
	return fs.Open(ctx, u.ID, u.Home, u.Permissions&PermissionFilesAll != 0)
}

type Manager interface {
	// create.go
	CreateUser(email, name string, noCreateHome bool) (User, error)

	// select.go
	ListUsers(since int64) ([]User, error)
	UserByEmail(email string) (User, error)
	UserHome(email string) (pgtype.UUID, error)

	// update.go
	UpdateUserHome(user User, home pgtype.UUID) error
	UpdateUserName(user User, name string) error
	UpdateUserPassword(user User, password string) error

	// auth.go
	VerifyUserPassword(email, password string) (User, error)
	CreateAccessToken(user User) (string, error)
	ReadAccessToken(accessToken string) (User, error)

	// reset.go
	CreateResetToken(user User) (string, error)
	ResetUserPassword(user User, token, password string) error

	// bookmarks.go
	AddBookmark(u User, resource fs.Resource, name string) (Bookmark, error)
	RemoveBookmark(u User, id uuid.UUID) error
	ListBookmarks(u User, since int64) ([]Bookmark, error)
}
