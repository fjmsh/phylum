package fs

type Permission = int32

const (
	PermissionNone  = Permission(0)
	PermissionRead  = Permission(4)
	PermissionWrite = Permission(32)
	PermissionShare = Permission(128)
	PermissionSU    = Permission(-1)
)
