-- name: CreateResource :one
INSERT INTO resources(
    id, parent, name, dir, content_type, content_sha256
) VALUES (
    @id::uuid, sqlc.narg('parent')::uuid, @name::text, @dir::boolean,
      CASE @dir WHEN TRUE THEN '' ELSE 'text/plain' END,
      CASE @dir WhEN TRUE THEN '' ELSE 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' END
) RETURNING *;

-- name: CreateResources :copyfrom
INSERT INTO resources(
    id, parent, name, dir, content_size, content_type, content_sha256
) VALUES (
    @id::uuid, @parent::uuid, @name::text, @dir::boolean, @content_size::bigint, @content_type::text, @content_sha256::text
);

-- name: ResourceByPath :one
SELECT * FROM resource_by_path(@path::text, @root::uuid, @username::text);

-- name: ResourceByID :one
SELECT * FROM resource_by_id(@resource_id::uuid, @root::uuid, @username::text);

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
RETURNING name, parent;

-- name: UpdateUserPermissionsForResource :one
UPDATE resources
SET
    permissions[@username::text] = to_json(@permission::int),
    modified = NOW()
WHERE id = @resource_id::uuid
RETURNING permissions;

-- name: RemoveUserPermissionForResource :one
UPDATE resources
SET
    permissions = permissions - @username::text,
    modified = NOW()
WHERE id = @resource_id::uuid
RETURNING permissions;

-- name: ChildResourceIDByName :one
SELECT id FROM resources WHERE parent = @parent::uuid AND name = @name::text AND deleted IS NULL;

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
), links(id, count) AS (
    SELECT root, count(p.id) FROM publinks p WHERE p.deleted IS NULL GROUP BY p.root
)
SELECT nodes.*, COALESCE(links.count, 0) AS publinks from nodes
LEFT JOIN links ON nodes.id = links.id
WHERE CASE WHEN @include_root::boolean THEN true ELSE depth > 0 END;

-- name: DeleteRecursive :many
WITH RECURSIVE nodes(id, parent, dir) AS (
    SELECT r.id, r.parent, r.dir
    FROM resources r WHERE r.id = @id::uuid
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


-- name: SharedResources :many
SELECT * FROM resources WHERE permissions ? @username::text AND id <> @user_home::uuid AND deleted IS NULL;