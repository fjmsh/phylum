package fs

import "fmt"

type Permission = int32

const (
	PermissionNone           = Permission(0)
	PermissionReadOnly       = Permission(3)
	PermissionReadWrite      = Permission(31)
	PermissionReadWriteShare = Permission(127)
)

func PermissionString(p Permission) string {
	switch p {
	case PermissionNone:
		return "none"
	case PermissionReadOnly:
		return "read"
	case PermissionReadWrite:
		return "write"
	case PermissionReadWriteShare:
		return "share"
	}
	return fmt.Sprintf("Unknown Permission (%d)", p)
}
