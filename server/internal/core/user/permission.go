package user

type Permission = int32

const (
	PermissionUsersInvite = Permission(0x10)
	PermissionUsersGrant  = Permission(0x20)
	PermissionFilesAll    = Permission(0x100)
)
