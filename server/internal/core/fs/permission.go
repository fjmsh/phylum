package fs

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
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
	return r.UserPermissions&p != 0
}

func (r Resource) PermissionsString() string {
	return permissionJsonString(r.Permissions)
}
func (r Resource) InheritedPermissionsString() string {
	return permissionJsonString(r.InheritedPermissions)
}

func permissionJsonString(j string) string {
	p := make(map[string]Permission)
	json.Unmarshal([]byte(j), &p)
	if len(p) == 0 {
		return ""
	}
	perm := make([]string, 0, len(p))
	for k, v := range p {
		perm = append(perm, k+": "+permissionString(v))
	}
	return "[" + strings.Join(perm, ", ") + "]"
}

func permissionString(p Permission) string {
	if p == PermissionSU {
		return "su"
	}
	str := ""
	if p&PermissionRead != 0 {
		p -= PermissionRead
		str += "r"
	}
	if p&PermissionWrite != 0 {
		p -= PermissionWrite
		str += "w"
	}
	if p&PermissionShare != 0 {
		p -= PermissionShare
		str += "s"
	}
	if p != 0 {
		str += fmt.Sprintf("u(%d)", p)
	}
	return str
}

func MergePermissionStrings(p1s, p2s string) (string, error) {
	p1 := make(map[string]Permission)
	json.Unmarshal([]byte(p1s), &p1)
	p2 := make(map[string]Permission)
	json.Unmarshal([]byte(p2s), &p2)
	for k, v := range p1 {
		p2[k] = p2[k] | v

	}
	res, err := json.Marshal(p2)
	if err != nil {
		return "", err
	}
	return string(res), nil
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
