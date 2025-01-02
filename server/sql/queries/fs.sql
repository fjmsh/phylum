-- name: CreateResource :one
INSERT INTO resources(
    id, parent, name, dir, content_length, content_type, content_sha256
) VALUES (
    @id::uuid, sqlc.narg('parent')::uuid, @name::text, @dir::boolean, @content_length::bigint, @content_type::text, @content_sha256::text
) RETURNING *;

-- name: CreateResources :copyfrom
INSERT INTO resources(
    id, parent, name, dir, content_length, content_type, content_sha256
) VALUES (
    @id::uuid, @parent::uuid, @name::text, @dir::boolean, @content_length::bigint, @content_type::text, @content_sha256::text
);

-- name: ResourceByPath :many
SELECT * FROM resource_by_id(resource_id_by_path(@path::text, sqlc.narg('root')::uuid));

-- name: ResourceByID :many
SELECT * FROM resource_by_id(@resource_id::uuid);

-- name: UpdateResourceContents :exec
UPDATE resources
SET
    content_length = $1,
    content_type = $2, 
    content_sha256 = $3,
    modified = NOW()
WHERE id = $4;

-- name: UpdateResourceModified :exec
UPDATE resources
SET
    modified = NOW()
WHERE id = $1;

-- name: UpdateResourceParent :one
UPDATE resources
SET
    parent = @parent::uuid,
    modified = NOW()
WHERE id = @id::uuid
RETURNING *;

-- name: UpdateResourceName :one
UPDATE resources
SET
    name = CASE WHEN (@name::text = '') THEN name ELSE @name::text END,
    modified = NOW()
WHERE id = @id::uuid
RETURNING *;

-- name: UpdateResourceNameParent :one
UPDATE resources
SET
    name = CASE WHEN (@name::text = '') THEN name ELSE @name::text END,
    parent = @parent::uuid,
    modified = NOW()
WHERE id = @id::uuid
RETURNING name, parent, modified;

-- name: UpdateUserPermissionsForResource :exec
INSERT INTO permissions(
    resource_id,
    username,
    modified,
    value
) VALUES (
    @resource_id::UUID,
    @username::TEXT,
    NOW(),
    @permission::INT
) ON CONFLICT(resource_id, username) DO UPDATE
SET
    modified = CURRENT_TIMESTAMP,
    value = @permission::INT;

-- name: ChildResourceByName :one
SELECT * FROM resources WHERE parent = @parent::uuid AND name = @name::text AND deleted IS NULL;

-- name: ReadDir :many
SELECT * from readdir(@resource_id::uuid, @min_depth::int, @max_depth::int);

-- name: DeleteRecursive :many
WITH RECURSIVE nodes(id, parent, dir) AS (
    SELECT r.id, r.parent, r.dir
    FROM resources r
    WHERE
        CASE @preserve_root::boolean
            WHEN TRUE THEN r.parent = @id::uuid
            ELSE r.id = @id::uuid
        END
  UNION ALL
    SELECT r.id, r.parent, r.dir
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
)
UPDATE resources
SET modified = NOW(), deleted = NOW()
WHERE id in (SELECT id FROM nodes)
RETURNING id, dir;

-- name: DiskUsage :one
WITH RECURSIVE nodes(id, parent, content_length, dir) AS (
    SELECT r.id, r.parent, r.content_length, r.dir
    FROM resources r WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent, r.content_length, r.dir
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
)
SELECT
  SUM(content_length) AS size,
  COUNT(*) AS entities,
  COUNT(CASE dir WHEN true THEN 1 ELSE NULL END) AS dirs,
  COUNT(CASE dir WHEN false THEN 1 ELSE NULL END) AS files
FROM nodes;
