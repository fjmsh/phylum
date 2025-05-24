package user

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type User struct {
	ID          int32
	Email       string
	DisplayName string
	Home        pgtype.UUID
	Permissions Permission
}

func scanUser(row pgx.CollectableRow) (User, error) {
	var u User
	err := row.Scan(
		&u.ID,
		&u.Email,
		&u.DisplayName,
		&u.Home,
		&u.Permissions,
	)
	return u, err
}

func (u User) OpenFileSystem(ctx context.Context) fs.FileSystem {
	return fs.Open(ctx, u.ID, u.Home, u.Permissions&PermissionAllFiles != 0)
}

type Manager interface {
	// create.go
	CreateUser(email, displayName string, home pgtype.UUID) (User, error)

	// select.go
	ListUsers(since *time.Time) ([]User, error)
	UserByEmail(email string) (User, error)
	UserHome(email string) (pgtype.UUID, error)

	// update.go
	UpdateUserHome(user User, home pgtype.UUID) error
	UpdateUserDisplayName(user User, displayName string) error
	UpdateUserPassword(user User, password string) error

	// auth.go
	VerifyUserPassword(email, password string) (User, error)
	CreateAccessToken(user User) (string, error)
	ReadAccessToken(accessToken string) (User, error)

	// reset.go
	CreateResetToken(user User) (string, error)

	// bookmarks.go
	AddBookmark(u User, resource fs.Resource, name string) (Bookmark, error)
	RemoveBookmark(u User, id uuid.UUID) error
	ListBookmarks(u User) ([]Bookmark, error)
}
