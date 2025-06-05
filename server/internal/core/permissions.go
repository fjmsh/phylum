package core

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type Permission = int32

const (
	PermissionNone  = Permission(0)
	PermissionRead  = Permission(4)
	PermissionWrite = Permission(32)
	PermissionShare = Permission(128)
	PermissionSU    = Permission(-1)
)

func (f filesystem) UpdatePermissions(r Resource, userID int32, permission Permission) (Resource, error) {
	if r.deleted.Valid {
		return r, ErrResourceDeleted
	}
	if !r.hasPermission(PermissionShare) {
		return Resource{}, ErrInsufficientPermissions
	}
	// Do not grant more than what you have
	permission = permission & r.userPermission
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
	if permission == PermissionNone {
		q = qRemove
	}

	var grants []byte
	err := f.runInTx(func(f filesystem) error {
		row := f.db.QueryRow(q, pgx.NamedArgs{
			"resource_id": r.id,
			"user_id":     userID,
			"permission":  permission,
		})

		if err := row.Scan(&grants); err != nil {
			return err
		}

		return f.recomputePermissions(r.id)
	})
	if err != nil {
		return Resource{}, err
	}

	r.grants = grants
	return r, nil
}

func (f filesystem) recomputePermissions(id uuid.UUID) error {
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

	_, err := f.db.Exec(q, id)
	return err
}
