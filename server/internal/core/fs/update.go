package fs

import (
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) UpdatePermissions(r Resource, username string, permission Permission) (Resource, error) {
	if !r.hasPermission(PermissionShare) {
		return Resource{}, ErrInsufficientPermissions
	}
	// Do not grant more than what you have
	permission = permission & r.UserPermissions

	var res db.Resource
	var err error
	if permission == 0 {
		res, err = f.db.RemoveUserPermissionForResource(f.ctx, db.RemoveUserPermissionForResourceParams{
			ResourceID: r.ID,
			Username:   username,
		})
	} else {
		res, err = f.db.UpdateUserPermissionsForResource(f.ctx, db.UpdateUserPermissionsForResourceParams{
			ResourceID: r.ID,
			Username:   username,
			Permission: permission,
		})
	}
	if err != nil {
		return Resource{}, err
	}
	return ResourceFromDB(res), nil
}
