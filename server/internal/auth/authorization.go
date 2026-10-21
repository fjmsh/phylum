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
	userPermissions core.UserPrivileges
	homeID          pgtype.UUID
	expires         pgtype.Timestamptz
	scopes          []string
}

func NewSUAuth(user core.User) *Auth {
	return &Auth{
		userID:          user.ID,
		userPermissions: user.Privileges,
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

func (a *Auth) UserPrivileges() core.UserPrivileges {
	return a.userPermissions
}

// HasScope checks whether or not this authorization includes the given scope,
// given the following rules:
//   - Scopes are nested using ":"
//   - All nested scopes are included for a given scope none are specified
//   - "*" matches all scopes at that level of nesting (above point applies)
//
// Examples:
//   - "user:profile" is included in "user", which is included in "*"
//   - "files:read:id" is included in "files:read", as well as "files:*:id"
//     which are both included in "files", which itself is included in "*"
func (a *Auth) HasScope(scope string) bool {
	parts := strings.Split(scope, ":")

outer:
	for _, s := range a.scopes {
		for i, p := range strings.Split(s, ":") {
			if p != "*" && (i >= len(parts) || p != parts[i]) {
				continue outer
			}
		}
		return true
	}
	return false
}

func (a *Auth) GetFileSystem(db db.Handler, rootOverride pgtype.UUID) *core.FileSystem {
	pathRoot := rootOverride
	if !pathRoot.Valid {
		pathRoot = a.homeID
	}
	var scopes []string
	for _, s := range a.scopes {
		if s == "*" || s == "files" {
			return core.OpenFileSystem(db, pathRoot, a.userID, a.userPermissions, []string{"*"})
		}
		if filesScope, found := strings.CutPrefix(s, "files:"); found {
			scopes = append(scopes, filesScope)
		}
	}
	return core.OpenFileSystem(db, pathRoot, a.userID, a.userPermissions, scopes)
}
