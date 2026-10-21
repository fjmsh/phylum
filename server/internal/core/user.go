package core

import (
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type UserPrivileges []UserPrivilege
type UserPrivilege = string

const (
	UserPrivilegeFilesAll               = UserPrivilege("files")
	UserPrivilegeFilesRead              = UserPrivilege("files:read")
	UserPrivilegeFilesWrite             = UserPrivilege("files:write")
	UserPrivilegeFilesShare             = UserPrivilege("files:share")
	UserPrivilegeConfigAuthAll          = UserPrivilege("config:auth")
	UserPrivilegeConfigAuthRead         = UserPrivilege("config:auth:read")
	UserPrivilegeConfigAuthUpdate       = UserPrivilege("config:auth:update")
	UserPrivilegeConfigMailAll          = UserPrivilege("config:mail")
	UserPrivilegeConfigMailRead         = UserPrivilege("config:mail:read")
	UserPrivilegeConfigMailValidate     = UserPrivilege("config:mail:validate")
	UserPrivilegeConfigMailUpdate       = UserPrivilege("config:mail:update")
	UserPrivilegeUserAuthPasswordUpdate = UserPrivilege("user:auth:password:update")
	UserPrivilegeUserPrivilegesUpdate   = UserPrivilege("user:permissions:update")
	UserPrivilegeUsersAll               = UserPrivilege("users")
	UserPrivilegeUsersList              = UserPrivilege("users:list")
	UserPrivilegeUsersCreate            = UserPrivilege("users:create")
	UserPrivilegeUsersCreateInvite      = UserPrivilege("users:create:invite")
	UserPrivilegeSU                     = UserPrivilege("*")
)

type User struct {
	ID          int32
	Email       string
	Name        string
	Home        pgtype.UUID
	Permissions UserPrivileges
}

func (u UserPrivileges) HasPermission(p UserPrivilege) bool {
	if p == UserPrivilegeUsersCreateInvite && allowInvites {
		return true
	}
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

func (u UserPrivileges) GetFilesPermissions() ResourcePermission {
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
