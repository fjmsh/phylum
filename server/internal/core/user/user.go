package user

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type BasicUser struct {
	Username    string
	DisplayName string
}

type User struct {
	BasicUser
	PasswordHash string
	Home         pgtype.UUID
	Permissions  int32
}

func scanBasicUser(row pgx.CollectableRow) (BasicUser, error) {
	var u BasicUser
	err := row.Scan(
		&u.Username,
		&u.DisplayName,
	)
	return u, err
}

func scanUser(row pgx.CollectableRow) (User, error) {
	var u User
	err := row.Scan(
		&u.Username,
		&u.DisplayName,
		&u.PasswordHash,
		&u.Home,
		&u.Permissions,
	)
	return u, err
}

func (u User) OpenFileSystem(ctx context.Context, id pgtype.UUID) fs.FileSystem {
	return fs.Open(ctx, u.Username, id, u.Permissions&PermissionAllFiles != 0)
}

func (u User) OpenHomeFileSystem(ctx context.Context) fs.FileSystem {
	return u.OpenFileSystem(ctx, u.Home)
}

type Manager interface {
	// create.go
	CreateUser(username, displayName, password string, home pgtype.UUID) (User, error)

	// select.go
	ListUsers(since *time.Time) ([]BasicUser, error)
	UserByUsername(email string) (User, error)
	UserHome(username string) (pgtype.UUID, error)

	// update.go
	UpdateUserHome(user User, home pgtype.UUID) error
	UpdateUserDisplayName(user User, displayName string) error
	UpdateUserPassword(user User, password string) error

	// auth.go
	VerifyUserPassword(email, password string) (User, error)
	CreateAccessToken(username string) (string, error)
	ReadAccessToken(accessToken string) (User, error)

	// bookmarks.go
	AddBookmark(u User, resource fs.Resource, name string) (Bookmark, error)
	RemoveBookmark(u User, id uuid.UUID) error
	ListBookmarks(u User) ([]Bookmark, error)
}
