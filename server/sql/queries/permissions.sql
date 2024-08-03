
-- name: PermissionsForResource :one
WITH RECURSIVE nodes(id, parent, permission) AS (
    SELECT r.id, r.parent, p.permission
    FROM resources r LEFT JOIN permissions p on r.id = p.resource_id WHERE r.id = @resource_id::uuid AND p.username = @username::text
  UNION ALL
    SELECT r.id, r.parent, CASE WHEN (n.permission IS NULL OR p.permission > n.permission) THEN p.permission ELSE n.permission END
    FROM resources r JOIN nodes n ON r.id = n.parent LEFT JOIN permissions p ON r.id = p.resource_id AND p.username = @username::text
)
SELECT * FROM nodes WHERE parent IS NULL;