package fs

import (
	"time"

	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) UpdateName(r Resource, name string) (Resource, error) {
	if r, err := f.db.UpdateResourceName(f.ctx, db.UpdateResourceNameParams{ID: r.ID, Name: name}); err != nil {
		return Resource{}, err
	} else {
		var deleted *time.Time
		if r.Deleted.Valid {
			deleted = &r.Deleted.Time
		}
		return Resource{
			ID:            r.ID,
			ParentID:      r.Parent,
			Name:          r.Name,
			Created:       r.Created.Time,
			Modified:      r.Modified.Time,
			Deleted:       deleted,
			Dir:           r.Dir,
			ContentSize:   r.ContentSize,
			ContentType:   r.ContentType,
			ContentSHA256: r.ContentSha256,
			Permissions:   string(r.Permissions),
			// Not Needed
			// Path: r.Path,
			// UserPermissions: 0,
			// InheritedPermissions: "",
		}, nil
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
	var deleted *time.Time
	if res.Deleted.Valid {
		deleted = &res.Deleted.Time
	}
	return Resource{
		ID:            res.ID,
		ParentID:      res.Parent,
		Name:          res.Name,
		Created:       res.Created.Time,
		Modified:      res.Modified.Time,
		Deleted:       deleted,
		Dir:           res.Dir,
		ContentSize:   res.ContentSize,
		ContentType:   res.ContentType,
		ContentSHA256: res.ContentSha256,
		Permissions:   string(res.Permissions),
		// Not Needed
		// Path: r.Path,
		// UserPermissions: 0,
		// InheritedPermissions: "",
	}, nil
}
