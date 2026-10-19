package core

import (
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type UserPermissions []UserPermission
type UserPermission = string

const (
	UserPermissionFilesAll               = UserPermission("files")
	UserPermissionFilesRead              = UserPermission("files:read")
	UserPermissionFilesWrite             = UserPermission("files:write")
	UserPermissionFilesShare             = UserPermission("files:share")
	UserPermissionConfigAuthAll          = UserPermission("config:auth")
	UserPermissionConfigAuthRead         = UserPermission("config:auth:read")
	UserPermissionConfigAuthUpdate       = UserPermission("config:auth:update")
	UserPermissionConfigMailAll          = UserPermission("config:mail")
	UserPermissionConfigMailRead         = UserPermission("config:mail:read")
	UserPermissionConfigMailValidate     = UserPermission("config:mail:validate")
	UserPermissionConfigMailUpdate       = UserPermission("config:mail:update")
	UserPermissionUserAuthPasswordUpdate = UserPermission("user:auth:password:update")
	UserPermissionUserPermissionsUpdate  = UserPermission("user:permissions:update")
	UserPermissionUsersAll               = UserPermission("users")
	UserPermissionUsersList              = UserPermission("users:list")
	UserPermissionUsersCreate            = UserPermission("users:create")
	UserPermissionUsersCreateInvite      = UserPermission("users:create:invite")
	UserPermissionSU                     = UserPermission("*")
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

func (u UserPermissions) GetFilesPermissions() ResourcePermission {
	permissions := ResourcePermissionNone

	for _, s := range u {
		parts := strings.Split(string(s), ":")
		if parts[0] == "*" || parts[0] == "files" {
			if len(parts) == 1 {
				return ResourcePermissionsAll
			} else if len(parts) == 2 {
				switch parts[1] {
				case "read":
					permissions |= ResourcePermissionRead
				case "write":
					permissions |= ResourcePermissionWrite
				case "share":
					permissions |= ResourcePermissionShare
				case "*":
					permissions |= ResourcePermissionsAll
				}
			}
		}
	}
	return permissions
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
