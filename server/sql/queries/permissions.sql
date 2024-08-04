
-- name: ResourceByIdWithPermissions :one
WITH RECURSIVE nodes(id, parent, permission) AS (
    SELECT r.id, r.parent, p.permission
    FROM resources r
    LEFT JOIN permissions p
    on r.id = p.resource_id
    AND p.user_id = @user_id::int
    WHERE r.id = @resource_id::uuid 
  UNION ALL
    SELECT r.id, r.parent, CASE WHEN (n.permission IS NULL OR p.permission > n.permission) THEN p.permission ELSE n.permission END
    FROM resources r
    JOIN nodes n
    ON r.id = n.parent
    LEFT JOIN permissions p
    ON r.id = p.resource_id AND p.user_id = @user_id::int
    WHERE r.parent = @root::uuid
    OR r.parent = '00000000-0000-0000-0000-000000000000'
)
SELECT * FROM nodes n
JOIN resources r
ON n.id = r.id
WHERE n.parent = @root::uuid;

-- name: UpdatePermissionsForResource :exec
INSERT INTO permissions(resource_id, user_id, permission)
    VALUES(@resource_id::uuid, @user_id::int, @permission::int)
    ON CONFLICT(resource_id, user_id) DO UPDATE SET permission = @permission::int;

