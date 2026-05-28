package core

import (
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

	if up, err := readPermissionFromJson(r.permissions, f.userID); err != nil {
		return Resource{}, err
	} else {
		up |= f.userPermissions.GetFilesPermissions()
		if up&ResourcePermissionShare == 0 {
			return Resource{}, ErrInsufficientPermissions
		} else {
			// Do not grant more than the user has
			permission = permission & up
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
