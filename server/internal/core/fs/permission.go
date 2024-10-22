package fs

import (
	"errors"
	"fmt"
)

type Permission = int32

const (
	PermissionNone  = Permission(0)
	PermissionRead  = Permission(4)
	PermissionWrite = Permission(32)
	PermissionShare = Permission(128)
	PermissionSU    = Permission(-1)
)

func (r Resource) hasPermission(p Permission) bool {
	return (r.UserPermissions & p) != 0
}

func PermissionString(p Permission) string {
	if p == PermissionSU {
		return "su"
	}
	str := ""
	if p|PermissionRead != 0 {
		str += "r"
	}
	if p|PermissionWrite != 0 {
		str += "w"
	}
	if p|PermissionShare != 0 {
		str += "s"
	}
	if p != 0 {
		str += fmt.Sprintf("u%d", p)
	}
	return str
}

func ParsePermissionString(s string) (Permission, error) {
	switch s {
	case "none":
		return PermissionNone, nil
	case "read":
		return PermissionRead, nil
	case "write":
		return PermissionRead | PermissionWrite, nil
	case "share":
		return PermissionRead | PermissionWrite | PermissionShare, nil
	}
	return PermissionNone, errors.New("unrecognized permission: " + s)
}
