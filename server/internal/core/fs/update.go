package fs

import (
	"strings"

	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) UpdateName(r Resource, name string) (Resource, error) {
	// TODO: #badbehavior This should check parent permissions, not self
	if !r.hasPermission(PermissionWrite) {
		return Resource{}, ErrInsufficientPermissions
	}
	if name == "" || CheckNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}

	if res, err := f.db.UpdateResourceName(f.ctx, db.UpdateResourceNameParams{ID: r.ID, Name: name}); err != nil {
		return Resource{}, err
	} else {
		return ResourceFromDB(res, r.UserPermissions, r.Path[0:strings.LastIndex(r.Path, "/")]+"/"+name, r.InheritedPermissions), nil
	}
}

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
	return ResourceFromDB(res, r.UserPermissions, r.Path, r.InheritedPermissions), nil
}
