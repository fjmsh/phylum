
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
SELECT * FROM resource_by_path(@path::text, @root::uuid, @username::text);

-- name: ResourceByID :one
SELECT * FROM resource_by_id(@resource_id::uuid, @root::uuid, @username::text);

-- name: UpdateUserPermissionsForResource :one
UPDATE resources SET permissions[@username::text] = to_json(@permission::int) WHERE id = @resource_id::uuid RETURNING *;

-- name: RemoveUserPermissionForResource :one
UPDATE resources SET permissions = permissions - @username::text WHERE id = @resource_id::uuid RETURNING *;