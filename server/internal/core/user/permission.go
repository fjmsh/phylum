package user

type Permissions = int32

const (
	PermissionUsersInvite = Permissions(0x10)
	PermissionUsersGrant  = Permissions(0x20)
	PermissionFilesAll    = Permissions(0x100)
)
