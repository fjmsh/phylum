-- name: CreateResource :one
INSERT INTO resources(
    id, parent, name, dir
) VALUES (
    $1, $2, $3, $4
) RETURNING *;

-- name: UpdateResourceContents :exec
UPDATE resources
SET
    size = $1,
    sha256sum = $2,
    modified = NOW()
WHERE id = $3;

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
    parent = COALESCE(sqlc.narg('parent'), parent),
    modified = NOW()
WHERE id = @id::uuid
RETURNING *;

-- name: DiskUsage :one
WITH RECURSIVE nodes(id, parent, size, dir) AS (
    SELECT r.id, r.parent, r.size, r.dir
    FROM resources r WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent, r.size, r.dir
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
)
SELECT
  SUM(size) AS size,
  COUNT(*) AS entities,
  COUNT(CASE dir WHEN true THEN 1 ELSE NULL END) AS dirs,
  COUNT(CASE dir WHEN false THEN 1 ELSE NULL END) AS files
FROM nodes;


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
SET modified = NOW(), deleted = NOW()
WHERE id in (SELECT id FROM nodes)
RETURNING id;

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
RETURNING id;

-- name: SharedResources :many
SELECT * FROM resources where permissions ? @username::text AND id <> @user_home::uuid AND deleted IS NULL;