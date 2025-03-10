-- name: RecomputePermissions :exec
WITH RECURSIVE nodes(id, parent, permissions) AS (
    SELECT r.id, r.parent, CASE WHEN r.parent IS NULL THEN r.grants ELSE jsonb_bitwise_or(p.permissions, r.grants) END
        FROM resources r
        LEFT JOIN resources p
            ON r.parent = p.id
        WHERE r.id = @resource_id::uuid
    UNION ALL
        SELECT r.id, r.parent, jsonb_bitwise_or(n.permissions, r.grants)
            FROM resources r JOIN nodes n on r.parent = n.id
)
UPDATE resources
    SET permissions = nodes.permissions
    FROM nodes
    WHERE resources.id = nodes.id;
