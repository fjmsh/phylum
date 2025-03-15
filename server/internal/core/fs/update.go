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

	ctx := r.f.ctx
	err := r.f.db.WithTx(ctx, func(dbh *db.DbHandler) error {
		if permission == PermissionNone {
			if err := dbh.RevokeUserPermissionForResource(ctx, db.RevokeUserPermissionForResourceParams{
				ResourceID: r.ID(),
				Username:   username,
			}); err != nil {
				return err
			}
		} else {
			if err := dbh.GrantUserPermissionForResource(ctx, db.GrantUserPermissionForResourceParams{
				ResourceID: r.ID(),
				Username:   username,
				Permission: permission,
			}); err != nil {
				return err
			}
		}

		if err := dbh.RecomputePermissions(ctx, r.ID()); err != nil {
			return err
		}

		return nil
	})
	p := make(map[string]Permission)
	if r.permissions != nil {
		json.Unmarshal(r.permissions, &p)
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

	r.permissions = res
	return r, nil
}
