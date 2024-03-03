-- name: FindResource :one
SELECT * from resources WHERE id = $1;

-- name: FindRoot :one
SELECT * from resources WHERE deleted IS NULL AND parent IS NULL AND name = $1;

-- name: CreateResource :exec
INSERT INTO resources(
    id, parent, name, dir, created, modified
) VALUES (
    $1, $2, $3, $4, NOW(), NOW()
);

-- name: UpdateResourceContents :exec
UPDATE resources
SET
    size = $1,
    etag = $2,
    modified = NOW()
WHERE id = $3;


-- name: ReadDir :many
WITH RECURSIVE nodes(id, parent, name, dir, created, modified, size, etag, depth, path) AS (
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, 0, ''::text
    FROM resources r WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, n.depth + 1, concat(n.path, '/', r.name)
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
    AND CASE WHEN @recursive::boolean THEN true ELSE depth < 1 END
)
SELECT * from nodes;

-- name: ResourceByPath :one
WITH RECURSIVE nodes(id, parent, name, dir, created, modified, size, etag, depth, path, search) AS (
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, 0, concat('/', r.name)::text, @search::text[]
    FROM resources r WHERE r.id = @root::uuid
  UNION ALL
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, n.depth + 1, concat(n.path, '/', r.name), n.search
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
    AND r.name = n.search[n.depth + 2]
)
SELECT * FROM nodes WHERE cardinality(search) = depth + 1;

-- name: DeleteRecursive :many
WITH RECURSIVE nodes(id, parent) AS (
    SELECT r.id, r.parent
    FROM resources r WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
)
UPDATE resources
SET deleted = NOW()
WHERE id in (SELECT id FROM nodes)
RETURNING *;