
-- name: ReadDir :many
WITH RECURSIVE nodes(id, parent, name, dir, created, modified, size, sha256sum, depth, path, permissions) AS (
  SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.sha256sum, 0, ''::text, r.permissions
    FROM resources r
    WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.sha256sum, n.depth + 1, concat(n.path, '/', r.name), r.permissions
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
    AND r.id != @id::uuid
    AND CASE WHEN @recursive::boolean THEN true ELSE depth < 1 END
)
SELECT * from nodes
WHERE CASE WHEN @include_root::boolean THEN true ELSE depth > 0 END;

-- name: ResourceByPath :one
WITH RECURSIVE root(resid, id, parent, inherited_permissions) AS (
  SELECT @root::uuid, r.id, r.parent, '{}'::jsonb
    FROM resources r
    WHERE r.id = @root::uuid 
  UNION ALL
    SELECT n.resid, r.id, r.parent, jsonb_bitwise_or(r.permissions, n.permissions)
    FROM resources r
    JOIN nodes n
    ON r.id = n.parent
), nodes(id, parent, name, dir, created, modified, size, sha256sum, depth, path, search, permissions, inherited_permissions) AS (
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.sha256sum, 0, ''::text, @search::text[], r.permissions, root.inherited_permissions
    FROM resources r
    JOIN root
    ON r.id = n.resid WHERE parent IS NULL
  UNION ALL
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.sha256sum, n.depth + 1, concat(n.path, '/', r.name), n.search, r.permissions, jsonb_bitwise_or(r.permissions, n.permissions)
    FROM resources r
    JOIN nodes n ON r.parent = n.id
    WHERE deleted IS NULL
    AND r.name = n.search[n.depth + 1]
)
SELECT *, COALESCE((jsonb_bitwise_or(permissions, inherited_permissions)->((@user_id::int)::text))::int, 0)::int AS user_permission FROM nodes WHERE cardinality(search) = depth;

-- name: ResourceByID :one
WITH RECURSIVE nodes(resid, id, parent, inherited_permissions, found) AS (
  SELECT @resource_id::uuid, r.id, r.parent, '{}'::jsonb,
      CASE
        WHEN r.id = @root::uuid THEN true
        ELSE false
      END
    FROM resources r
    WHERE r.id = @resource_id::uuid 
  UNION ALL
    SELECT n.resid, r.id, r.parent, jsonb_bitwise_or(r.permissions, n.inherited_permissions),
      CASE
        WHEN r.id = @root::uuid THEN true
        ELSE n.found
      END
    FROM resources r
    JOIN nodes n
    ON r.id = n.parent
)
SELECT resid AS id, r.permissions, n.inherited_permissions, COALESCE((jsonb_bitwise_or(r.permissions, n.inherited_permissions)->((@user_id::int)::text))::int, 0)::int AS user_permission, found, r.parent, name, dir, created, modified, deleted, size, sha256sum FROM nodes n
JOIN resources r
ON r.id = n.resid
WHERE n.parent IS NULL;

-- name: UpdatePermissionsForResource :exec
UPDATE resources SET permissions[@user_id::integer] = @permission::int WHERE id = @resource_id::uuid;

-- -- name: GetLocalPermissionsForResource :many
-- SELECT p.user_id, CAST(p.permission AS INT) AS permission
--   FROM permissions p
--   WHERE p.resource_id = @resource_id::uuid;


-- -- name: GetInheritedPermissionsForResource :many
-- WITH RECURSIVE nodes(id, parent) AS (
--   SELECT r.id, r.parent
--     FROM resources r
--     WHERE r.id = @resource_id::uuid
--   UNION ALL (
--     SELECT r.id, r.parent
--      FROM resources r
--      JOIN nodes n
--      ON r.id = n.parent
--   )
-- )
-- SELECT p.user_id, CAST(MAX(p.permission) AS INT) AS permission
--   FROM permissions p
--   JOIN nodes n
--   ON n.id = p.resource_id
--   GROUP BY p.user_id;
