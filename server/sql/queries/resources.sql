-- name: CreateResource :one
INSERT INTO resources(
    id, parent, name, dir, content_type, content_sha256
) VALUES (
    @id::uuid, sqlc.narg('parent')::uuid, @name::text, @dir::boolean,
      CASE @dir WHEN TRUE THEN '' ELSE 'text/plain' END,
      CASE @dir WhEN TRUE THEN '' ELSE 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' END
) RETURNING *;

-- name: UpdateResourceContents :exec
UPDATE resources
SET
    content_size = $1,
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

-- name: DiskUsage :one
WITH RECURSIVE nodes(id, parent, content_size, dir) AS (
    SELECT r.id, r.parent, r.content_size, r.dir
    FROM resources r WHERE r.id = @id::uuid
  UNION ALL
    SELECT r.id, r.parent, r.content_size, r.dir
    FROM resources r JOIN nodes n on r.parent = n.id
    WHERE deleted IS NULL
)
SELECT
  SUM(content_size) AS size,
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
SELECT * FROM resources WHERE permissions ? @username::text AND id <> @user_home::uuid AND deleted IS NULL;

-- name: ChildResourceByName :one
SELECT * FROM resources WHERE parent = @parent::uuid AND name = @name::text AND deleted IS NULL;