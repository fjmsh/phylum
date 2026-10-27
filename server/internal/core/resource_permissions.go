package core

import (
	"encoding/json"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type ResourcePermission = int32

const (
	ResourcePermissionNone  = ResourcePermission(0)
	ResourcePermissionRead  = ResourcePermission(4)
	ResourcePermissionWrite = ResourcePermission(32)
	ResourcePermissionShare = ResourcePermission(128)
	ResourcePermissionsAll  = ResourcePermission(-1)
)

func (f *FileSystem) UpdatePermissions(r Resource, user User, permission ResourcePermission) (res Resource, err error) {
	err = f.runInTx(func(f txFileSystem) error {
		var err error
		res, err = f.UpdatePermissions(r, user, permission)
		return err
	})
	return res, err
}

func (f txFileSystem) UpdatePermissions(r Resource, user User, permission ResourcePermission) (Resource, error) {
	if r.deleted.Valid {
		return r, ErrResourceDeleted
	}
	// Make sure we have all the permissions we are about to grant (and the permission to share)
	if err := r.checkPermission(permission | ResourcePermissionShare); err != nil {
		return Resource{}, err
	}

	if f.IsUser(user.ID) && (permission&ResourcePermissionShare) == 0 {
		// User is removing their own permission. Check if there is somebody else with access
		if permissions, err := permissionFromJson(r.permissions); err != nil {
			return Resource{}, err
		} else {
			found := false
			for id, p := range permissions {
				if id == user.ID {
					continue
				}
				if p&ResourcePermissionShare == ResourcePermissionShare {
					found = true
					break
				}
			}
			if !found {
				return Resource{}, ErrPermissionsInvalid
			}
		}

	}

	const qUpdate = `
UPDATE resources SET
	grants[@user_id::INT] = jsonb_build_object('p', @permission::INT, 't', EXTRACT(EPOCH FROM NOW())::INTEGER),
	modified = NOW()
WHERE id = @resource_id::UUID
RETURNING grants`

	const qRemove = `
UPDATE resources SET
	grants = grants - @user_id::INT::TEXT,
	modified = NOW()
WHERE id = @resource_id::UUID
RETURNING grants`

	q := qUpdate
	if permission == ResourcePermissionNone {
		q = qRemove
	}

	var grants []byte
	row := f.db.QueryRow(q, pgx.NamedArgs{
		"resource_id": r.id,
		"user_id":     user.ID,
		"permission":  permission,
	})

	if err := row.Scan(&grants); err != nil {
		return Resource{}, err
	}

	if err := recomputePermissions(f.db, r.id); err != nil {
		return Resource{}, err
	}

	r.grants = grants
	return r, nil
}

func recomputePermissions(db db.TxHandler, id uuid.UUID) error {
	const q = `
WITH RECURSIVE nodes(id, parent, permissions) AS (
    SELECT r.id, r.parent, phylum_merge_permission_grants(COALESCE(p.permissions, '{}'::JSONB), r.grants) END
        FROM resources r
        LEFT JOIN resources p
            ON r.parent = p.id
        WHERE r.id = $1::UUID
    UNION ALL
        SELECT r.id, r.parent, phylum_merge_permission_grants(n.permissions, r.grants)
            FROM resources r JOIN nodes n on r.parent = n.id
)
UPDATE resources
    SET permissions = nodes.permissions
    FROM nodes
    WHERE resources.id = nodes.id`

	_, err := db.Exec(q, id)
	return err
}

func (f *FileSystem) getApiKeyScopePermissions(resourceID uuid.UUID, ancestors uuid.UUIDs) ResourcePermission {
	scopePermissions := f.allResourcesScope | f.scopedResources[resourceID]
	for _, id := range ancestors {
		scopePermissions |= f.scopedResources[id]
	}
	return scopePermissions
}

func (f *FileSystem) getUserPermission(permissionsJson []byte) (ResourcePermission, error) {
	if permissions, err := permissionFromJson(permissionsJson); err != nil {
		return 0, err
	} else {
		return f.userFilesPrivilege | permissions[f.userID], nil
	}
}

func (r Resource) checkPermission(p ResourcePermission) error {
	if r.apiKeyScope&p != p {
		return ErrInsufficientScope
	}
	if r.userPermissions&p != p {
		return ErrInsufficientPermissions
	}
	return nil
}

func (f *FileSystem) checkPermissionsForResourceWithID(resourceID uuid.UUID, p ResourcePermission) error {
	const q = `WITH RECURSIVE ancestors(id, parent) AS (
	SELECT id, parent FROM resources WHERE id = @id::UUID
	UNION ALL                                               
	SELECT a.id, r.parent FROM resources r JOIN ancestors a ON r.id = a.parent
) SELECT r.permissions, (SELECT array_agg(parent) FROM ancestors WHERE parent IS NOT NULL)
	FROM resources r
	WHERE r.id = @id::UUID`

	args := pgx.NamedArgs{
		"id": resourceID,
	}

	row := f.db.QueryRow(q, args)
	var permissionsJson []byte
	var ancestors uuid.UUIDs
	if err := row.Scan(&permissionsJson, &ancestors); err != nil {
		return err
	} else if scopePermissions := f.getApiKeyScopePermissions(resourceID, ancestors); scopePermissions&p != p {
		return ErrInsufficientScope
	} else if permissions, err := permissionFromJson(permissionsJson); err != nil {
		return err
	} else if (f.userFilesPrivilege|permissions[f.userID])&p != p {
		return ErrInsufficientPermissions
	}
	return nil
}

func permissionFromJson(j []byte) (map[int32]ResourcePermission, error) {
	if j == nil {
		return nil, nil
	}
	p := make(map[int32]ResourcePermission)
	err := json.Unmarshal(j, &p)
	if err != nil {
		return nil, err
	}
	return p, nil
}
