package fs

import (
	"github.com/shroff/phylum/server/internal/core/db"
)

func (r Resource) UpdatePermissions(username string, permission Permission) (Resource, error) {
	if !r.hasPermission(PermissionShare) {
		return Resource{}, ErrInsufficientPermissions
	}
	// Do not grant more than what you have
	permission = permission & r.UserPermissions

	var res db.Resource
	var err error
	if permission == 0 {
		res, err = r.f.db.RemoveUserPermissionForResource(r.f.ctx, db.RemoveUserPermissionForResourceParams{
			ResourceID: r.ID,
			Username:   username,
		})
	} else {
		res, err = r.f.db.UpdateUserPermissionsForResource(r.f.ctx, db.UpdateUserPermissionsForResourceParams{
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
