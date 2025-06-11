package core

import (
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type UserPermissions = int32

const (
	PermissionUsersInvite = UserPermissions(0x10)
	PermissionUsersGrant  = UserPermissions(0x20)
	PermissionFilesAll    = UserPermissions(0x100)
)

type User struct {
	ID          int32
	Email       string
	Name        string
	Home        pgtype.UUID
	Permissions UserPermissions
}

func (u User) hasPermission(p UserPermissions) bool {
	return u.Permissions&p != 0
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
