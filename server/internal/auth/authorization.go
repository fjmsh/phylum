package auth

import (
	"strings"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5/pgtype"
)

type Auth interface {
	UserID() int32
	UserPermissions() core.UserPermissions
	HasScope(scope string) bool
	GetFileSystem(db db.Handler, rootOverride pgtype.UUID) *core.FileSystem
}

type auth struct {
	userID          int32
	userPermissions core.UserPermissions
	homeID          pgtype.UUID // TODO: Make sure this is specified everywhere
	scopes          []string
}

func (a auth) UserID() int32 {
	return a.userID
}

func (a auth) UserPermissions() core.UserPermissions {
	return a.userPermissions
}

func (a auth) HasScope(scope string) bool {
	for _, s := range a.scopes {
		if s == "*" {
			return true
		}
	}
	return false
}

func (a auth) GetFileSystem(db db.Handler, rootOverride pgtype.UUID) *core.FileSystem {
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
