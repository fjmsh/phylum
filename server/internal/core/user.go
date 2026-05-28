package core

import (
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type UserPermissions []UserPermission
type UserPermission = string

const (
	UserPermissionUsersInvite = UserPermission("users:invite")
	UserPermissionUsersGrant  = UserPermission("users:grant")
	UserPermissionFilesAll    = UserPermission("files")
	UserPermissionFilesRead   = UserPermission("files:read")
	UserPermissionFilesWrite  = UserPermission("files:write")
	UserPermissionFilesShare  = UserPermission("files:share")
	UserPermissionSU          = UserPermission("*")
)

type User struct {
	ID          int32
	Email       string
	Name        string
	Home        pgtype.UUID
	Permissions UserPermissions
}

func (u UserPermissions) HasPermission(p UserPermission) bool {
	parts := strings.Split(string(p), ":")

outer:
	for _, s := range u {
		for i, p := range strings.Split(string(s), ":") {
			if p != "*" && (i >= len(parts) || p != parts[i]) {
				continue outer
			}
		}
		return true
	}
	return false
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
