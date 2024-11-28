package fs

import (
	"encoding/json"

	"github.com/shroff/phylum/server/internal/core/db"
)

func (r Resource) UpdatePermissions(username string, permission Permission) (Resource, error) {
	if !r.hasPermission(PermissionShare) {
		return Resource{}, ErrInsufficientPermissions
	}
	// Do not grant more than what you have
	permission = permission & r.userPermission

	var err error
	err = r.f.db.UpdateUserPermissionsForResource(r.f.ctx, db.UpdateUserPermissionsForResourceParams{
		ResourceID: r.ID(),
		Username:   username,
		Permission: permission,
	})
	if err != nil {
		return Resource{}, err
	}
	p := make(map[string]Permission)
	if r.Info.permissions != nil {
		json.Unmarshal(r.Info.permissions, &p)
	}
	if permission == 0 {
		delete(p, username)
	} else {
		p[username] = permission
	}
	res, err := json.Marshal(p)
	if err != nil {
		return Resource{}, err
	}

	r.Info.permissions = res
	return r, nil
}
