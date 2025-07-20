package auth

import (
	"errors"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5/pgtype"
)

type Auth struct {
	userID          int32
	userPermissions core.UserPermissions
	homeID          pgtype.UUID
	expires         pgtype.Timestamptz
	scopes          []string
}

func NewSUAuth(user core.User) *Auth {
	return &Auth{
		userID:          user.ID,
		userPermissions: user.Permissions,
		homeID:          user.Home,
		expires:         pgtype.Timestamptz{},
		scopes:          []string{"*"},
	}
}

func NewAuth(auth *Auth, expires pgtype.Timestamptz, scopes []string) (*Auth, error) {
	if len(scopes) == 0 {
		return nil, errors.New("must specify at least one scope")
	}

	// Make sure the generated key doesn't expire after the key that generated it
	if auth.expires.Valid && (!expires.Valid || expires.Time.After(auth.expires.Time)) {
		expires = auth.expires
	}
	for _, s := range scopes {
		if !auth.HasScope(s) {
			return nil, errors.New("cannot grant scopes that are not present")
		}
	}

	return &Auth{
		userID:          auth.userID,
		userPermissions: auth.userPermissions,
		homeID:          auth.homeID,
		expires:         expires,
		scopes:          scopes,
	}, nil
}

func (a *Auth) UserID() int32 {
	return a.userID
}

func (a *Auth) UserPermissions() core.UserPermissions {
	return a.userPermissions
}

func (a *Auth) HasScope(scope string) bool {
	for _, s := range a.scopes {
		if s == "*" {
			return true
		}
	}
	return false
}

func (a *Auth) GetFileSystem(db db.Handler, rootOverride pgtype.UUID) *core.FileSystem {
	pathRoot := rootOverride
	if !pathRoot.Valid {
		pathRoot = a.homeID
	}
	var fsScopes []string
	for _, s := range a.scopes {
		if s == "*" || s == "fs" {
			return core.OpenFileSystem(db, pathRoot, a.userID, a.userPermissions, []string{"*"})
		}
		if strings.HasPrefix(s, "fs:") {
			fsScopes = append(fsScopes, strings.TrimPrefix(s, "fs:"))
		}
	}
	return core.OpenFileSystem(db, pathRoot, a.userID, a.userPermissions, fsScopes)
}
