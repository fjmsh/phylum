package fs

import (
	"github.com/shroff/phylum/server/internal/core/db"
)

func (r Resource) UpdatePermissions(username string, permission Permission) (Resource, error) {
	if !r.hasPermission(PermissionShare) {
		return Resource{}, ErrInsufficientPermissions
	}
	// Do not grant more than what you have
	permission = permission & r.userPermission

	var p []byte
	var err error
	err = r.f.db.UpdateUserPermissionsForResource(r.f.ctx, db.UpdateUserPermissionsForResourceParams{
		ResourceID: r.ID(),
		Username:   username,
		Permission: permission,
	})
	if err != nil {
		return Resource{}, err
	}
	r.Info.permissions = p
	return r, nil
}
