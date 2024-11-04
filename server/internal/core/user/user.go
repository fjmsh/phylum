package user

import (
	"context"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type User struct {
	Username    string    `json:"username"`
	DisplayName string    `json:"display"`
	Root        uuid.UUID `json:"-"`
	Home        uuid.UUID `json:"-"`
}

func (u User) OpenFileSystem(ctx context.Context) fs.FileSystem {
	return fs.Open(ctx, u.Username, u.Root)
}

type Manager interface {
	// manager.go
	WithDb(db *db.DbHandler) Manager

	// create.go
	CreateUser(username, displayName, password string, root uuid.UUID) (User, error)

	// select.go
	AllUsers() ([]User, error)
	UserByEmail(email string) (User, error)

	// update.go
	UpdateUserRoot(user User, root uuid.UUID) error
	UpdateUserHome(user User, home uuid.UUID) error
	UpdateUserDisplayName(user User, displayName string) error

	// auth.go
	VerifyUserPassword(email, password string) (User, error)
	CreateAccessToken(username string) (string, error)
	ReadAccessToken(accessToken string) (User, error)

	// user_lists.go
	SharedResources(u User) (result []fs.ResourceInfo, err error)
	Bookmarks(u User) ([]fs.ResourceInfo, error)
	AddBookmark(u User, resource fs.Resource) error
	RemoveBookmark(u User, id uuid.UUID) error
}
