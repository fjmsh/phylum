
-- name: ReadDir :many
WITH RECURSIVE nodes(id, parent, name, dir, created, modified, size, etag, depth, path, permission) AS (
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, 0, ''::text, @permission::int
    FROM resources r
    WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, n.depth + 1, concat(n.path, '/', r.name),
      CASE
        WHEN p.permission > n.permission THEN p.permission
        ELSE n.permission
      END
    FROM resources r JOIN nodes n on r.parent = n.id
    LEFT JOIN permissions p
    ON r.id = p.resource_id 
    AND p.user_id = @user_id::int
    WHERE deleted IS NULL
    AND r.id != @id::uuid
    AND CASE WHEN @recursive::boolean THEN true ELSE depth < 1 END
)
SELECT * from nodes
WHERE CASE WHEN @include_root::boolean THEN true ELSE depth > 0 END;

-- name: ResourceByPath :one
WITH RECURSIVE nodes(id, parent, name, dir, created, modified, size, etag, depth, path, search, permission) AS (
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, 0, ''::text, @search::text[], @permission::int
    FROM resources r
    WHERE r.id = @root::uuid
  UNION ALL
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, n.depth + 1, concat(n.path, '/', r.name), n.search,
      CASE
        WHEN p.permission > n.permission THEN p.permission
        ELSE n.permission
      END
    FROM resources r
    JOIN nodes n ON r.parent = n.id
    LEFT JOIN permissions p
    ON r.id = p.resource_id 
    AND p.user_id = @user_id::int
    WHERE deleted IS NULL
    AND r.name = n.search[n.depth + 1]
)
SELECT * FROM nodes WHERE cardinality(search) = depth;

-- name: ResourceByID :one
WITH RECURSIVE nodes(resid, id, parent, found, permission) AS (
  SELECT @resource_id::uuid, r.id, r.parent,
      CASE
        WHEN r.id = @root::uuid THEN true
        ELSE false
      END,
      CASE
        WHEN p.permission IS NOT NULL THEN p.permission
        ELSE 0
      END
    FROM resources r
    LEFT JOIN permissions p
    ON p.resource_id = r.id
    AND p.user_id = @user_id::int
    WHERE r.id = @resource_id::uuid 
  UNION ALL
    SELECT n.resid, r.id, r.parent,
      CASE
        WHEN r.id = @root::uuid THEN true
        ELSE n.found
      END,
      CASE
        WHEN p.permission > n.permission THEN p.permission
        ELSE n.permission
      END
    FROM resources r
    JOIN nodes n
    ON r.id = n.parent
    LEFT JOIN permissions p
    ON r.id = p.resource_id AND p.user_id = @user_id::int
)
SELECT resid AS id, found, permission, r.parent, name, dir, created, modified, deleted, size, etag FROM nodes n
JOIN resources r
ON r.id = n.resid
WHERE n.parent IS NULL;

-- name: UpdatePermissionsForResource :exec
INSERT INTO permissions(resource_id, user_id, permission)
    VALUES(@resource_id::uuid, @user_id::int, @permission::int)
    ON CONFLICT(resource_id, user_id) DO UPDATE SET permission = @permission::int;

-- name: GetPermissionsForResourceSpecific :many
SELECT p.user_id, CAST(p.permission AS INT) AS permission
  FROM permissions p
  WHERE p.resource_id = @resource_id::uuid;


-- name: GetPermissionsForResourceInherited :many
WITH RECURSIVE nodes(id, parent) AS (
  SELECT r.id, r.parent
    FROM resources r
    WHERE r.id = @resource_id::uuid
  UNION ALL (
    SELECT r.id, r.parent
     FROM resources r
     JOIN nodes n
     ON r.id = n.parent
  )
)
SELECT p.user_id, CAST(MAX(p.permission) AS INT) AS permission
  FROM permissions p
  JOIN nodes n
  ON n.id = p.resource_id
  GROUP BY p.user_id;
