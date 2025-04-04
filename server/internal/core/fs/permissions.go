package fs

import (
	"encoding/json"

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

func (r Resource) UpdatePermissions(username string, permission Permission) (Resource, error) {
	if !r.hasPermission(PermissionShare) {
		return Resource{}, ErrInsufficientPermissions
	}
	// Do not grant more than what you have
	permission = permission & r.userPermission
	const q = `
UPDATE resources SET
	grants[@username::TEXT] = jsonb_build_object('p', @permission::INT, 't', EXTRACT(EPOCH FROM NOW())::INTEGER)"
	grants = (CASE permissions WHEN 0 THEN grants - @username::TEXT ELSE grants END)
	modified = NOW()
WHERE id = @resource_id::UUID`

	err := r.f.runInTx(func(f filesystem) error {
		if _, err := f.db.Exec(q, pgx.NamedArgs{
			"resource_id": r.id,
			"username":    username,
			"permission":  permission,
		}); err != nil {
			return err
		}

		return f.recomputePermissions(r.id)
	})
	if err != nil {
		return Resource{}, err
	}
	p := make(map[string]Permission)
	if r.permissions != nil {
		if err := json.Unmarshal(r.permissions, &p); err != nil {
			return Resource{}, err
		}
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
