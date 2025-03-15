-- name: GrantUserPermissionForResource :exec
UPDATE resources
SET
    grants[@username::text] = jsonb_build_object('p', @permission::INT, 't', EXTRACT(EPOCH FROM NOW())::INTEGER),
    modified = NOW()
WHERE id = @resource_id::uuid
RETURNING permissions;

-- name: RevokeUserPermissionForResource :exec
UPDATE resources
SET
    grants = grants - @username::TEXT,
    modified = NOW()
WHERE id = @resource_id::uuid
RETURNING permissions;

-- name: RecomputePermissions :exec
WITH RECURSIVE nodes(id, parent, permissions) AS (
    SELECT r.id, r.parent, phylum_merge_permission_grants(COALESCE(p.permissions, '{}'::JSONB), r.grants) END
        FROM resources r
        LEFT JOIN resources p
            ON r.parent = p.id
        WHERE r.id = @resource_id::uuid
    UNION ALL
        SELECT r.id, r.parent, phylum_merge_permission_grants(n.permissions, r.grants)
            FROM resources r JOIN nodes n on r.parent = n.id
)
UPDATE resources
    SET permissions = nodes.permissions
    FROM nodes
    WHERE resources.id = nodes.id;
