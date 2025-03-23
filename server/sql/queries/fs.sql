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

-- name: ResourceByPath :one
WITH RECURSIVE nodes(id, parent, search, depth) AS (
    SELECT r.id, r.parent, array_remove(string_to_array(@path::text, '/', NULL), ''), 0
        FROM resources r
        WHERE r.id = sqlc.narg('root')::UUID OR (r.parent IS NULL AND sqlc.narg('root')::UUID IS NULL)
    UNION ALL
        SELECT r.id, r.parent, n.search, n.depth + 1
            FROM resources r
            JOIN nodes n
                ON r.parent = n.id
            WHERE deleted IS NULL
            AND r.name = n.search[n.depth + 1]
)
SELECT r.*
    FROM nodes n
    JOIN resources r
        ON r.id = n.id
    WHERE cardinality(n.search) = n.depth;

-- name: GetAncestors :many
WITH RECURSIVE nodes(id, name, parent, permissions, self) AS (
    SELECT r.id, r.name, r.parent, r.permissions, TRUE
        FROM resources r
        WHERE r.id = @resource_id::UUID
    UNION ALL
        SELECT r.id, r.name, r.parent, r.permissions, FALSE
            FROM resources r
            JOIN nodes n ON r.id = n.parent
)
SELECT id, name, parent, permissions FROM nodes WHERE self = FALSE;

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
RETURNING *;

-- name: ChildResourceByName :one
SELECT * FROM resources WHERE parent = @parent::uuid AND name = @name::text AND deleted IS NULL;

-- name: ReadDir :many
WITH RECURSIVE nodes(id, parent, deleted, depth) AS (
    SELECT r.id, r.parent, r.deleted, 0
        FROM resources r
        WHERE r.id = @resource_id::UUID
    UNION ALL
        SELECT r.id, r.parent, n.deleted, n.depth + 1
            FROM resources r
            JOIN nodes n ON r.parent = n.id
            WHERE r.deleted IS NOT DISTINCT FROM n.deleted
            AND n.depth < @max_depth::INTEGER
)
SELECT r.*
    FROM nodes n
    JOIN resources r
        ON n.id = r.id
    WHERE n.depth >= @min_depth::INTEGER;

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
