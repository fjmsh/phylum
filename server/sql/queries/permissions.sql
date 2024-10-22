
-- name: ReadDir :many
WITH RECURSIVE nodes(id, parent, name, dir, created, modified, content_size, content_type, content_sha256, depth, path, permissions) AS (
  SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.content_size, r.content_type, r.content_sha256, 0, ''::text, r.permissions
    FROM resources r
    WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.content_size, r.content_type, r.content_sha256, n.depth + 1, concat(n.path, '/', r.name), r.permissions
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
    AND r.id != @id::uuid
    AND CASE WHEN @recursive::boolean THEN true ELSE depth < 1 END
)
SELECT * from nodes
WHERE CASE WHEN @include_root::boolean THEN true ELSE depth > 0 END;

-- name: ResourceByPath :one
WITH RECURSIVE nodes(id, parent, search, depth) AS (
    SELECT r.id, r.parent, @search::text[], 0
    FROM resources r
    WHERE r.id = @root::uuid
  UNION ALL
    SELECT r.id, r.parent, n.search, n.depth + 1
    FROM resources r
    JOIN nodes n ON r.parent = n.id
    WHERE deleted IS NULL
    AND r.name = n.search[n.depth + 1]
)
SELECT * FROM nodes WHERE cardinality(search) = depth;

-- name: ResourceByID :one
SELECT * FROM resource_by_id(@resource_id::uuid, @root::uuid, @username::text);

-- name: UpdateUserPermissionsForResource :one
UPDATE resources SET permissions[@username::text] = to_json(@permission::int) WHERE id = @resource_id::uuid RETURNING *;

-- name: RemoveUserPermissionForResource :one
UPDATE resources SET permissions = permissions - @username::text WHERE id = @resource_id::uuid RETURNING *;