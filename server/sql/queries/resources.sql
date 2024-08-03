-- name: ResourceById :one
SELECT * from resources WHERE id = $1;

-- name: CreateResource :one
INSERT INTO resources(
    id, parent, name, dir, created, modified
) VALUES (
    $1, $2, $3, $4, NOW(), NOW()
) RETURNING *;

-- name: UpdateResourceContents :exec
UPDATE resources
SET
    size = $1,
    etag = $2,
    modified = NOW()
WHERE id = $3;

-- name: UpdateResourceModified :exec
UPDATE resources
SET
    modified = NOW()
WHERE id = $1;

-- name: Rename :exec
UPDATE resources
SET
    name = CASE WHEN (@name::text = '') THEN name ELSE @name::text END,
    parent = @parent::uuid,
    modified = NOW()
WHERE id = @id::uuid;


-- name: ReadDir :many
WITH RECURSIVE nodes(id, parent, name, dir, created, modified, size, etag, depth, path, permission) AS (
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, 0, ''::text, p.permission
    FROM resources r
    LEFT JOIN permissions p
    ON r.id = p.resource_id
    AND p.username = @username::text
    WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, n.depth + 1, concat(n.path, '/', r.name), CASE WHEN (p.permission IS NULL OR p.permission < n.permission) THEN n.permission ELSE p.permission END
    FROM resources r JOIN nodes n on r.parent = n.id
    LEFT JOIN permissions p
    ON r.id = p.resource_id 
    AND p.username = @username::text
    WHERE deleted IS NULL
    AND CASE WHEN @recursive::boolean THEN true ELSE depth < 1 END
)
SELECT * from nodes
WHERE CASE WHEN @include_root::boolean THEN true ELSE depth > 0 END;

-- name: ResourceByPath :one
WITH RECURSIVE nodes(id, parent, name, dir, created, modified, size, etag, depth, path, search, permission) AS (
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, 0, ''::text, @search::text[], p.permission
    FROM resources r
    LEFT JOIN permissions p
    ON r.id = p.resource_id 
    AND p.username = @username::text
    WHERE r.id = @root::uuid
  UNION ALL
    SELECT r.id, r.parent, r.name, r.dir, r.created, r.modified, r.size, r.etag, n.depth + 1, concat(n.path, '/', r.name), n.search, CASE WHEN (p.permission IS NULL OR p.permission < n.permission) THEN n.permission ELSE p.permission END
    FROM resources r
    JOIN nodes n ON r.parent = n.id
    LEFT JOIN permissions p
    ON r.id = p.resource_id 
    AND p.username = @username::text
    WHERE deleted IS NULL
    AND r.name = n.search[n.depth + 1]
)
SELECT * FROM nodes WHERE cardinality(search) = depth;

-- name: DeleteRecursive :exec
WITH RECURSIVE nodes(id, parent) AS (
    SELECT r.id, r.parent
    FROM resources r WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
)
UPDATE resources
SET modified = NOW(), deleted = NOW()
WHERE id in (SELECT id FROM nodes);

-- name: HardDeleteRecursive :many
WITH RECURSIVE nodes(id, parent) AS (
    SELECT r.id, r.parent
    FROM resources r WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
)
DELETE FROM resources
WHERE id in (SELECT id FROM nodes)
RETURNING id, dir;
