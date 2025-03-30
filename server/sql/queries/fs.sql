-- name: CreateResources :copyfrom
INSERT INTO resources(
    id, parent, name, dir, content_length, content_type, content_sha256
) VALUES (
    @id::uuid, @parent::uuid, @name::text, @dir::boolean, @content_length::bigint, @content_type::text, @content_sha256::text
);

-- name: UpdateResourceContents :exec
UPDATE resources
SET
    content_length = $1,
    content_type = $2, 
    content_sha256 = $3,
    modified = NOW()
WHERE id = $4;