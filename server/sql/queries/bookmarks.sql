-- name: AddBookmark :one
INSERT INTO bookmarks(
    username,
    resource_id,
    name,
    dir
) VALUES (
    @username::TEXT,
    @resource_id::UUID,
    @name::TEXT,
    @dir::BOOLEAN
) ON CONFLICT(username, resource_id) DO UPDATE
SET
    created = CASE WHEN bookmarks.deleted IS NULL THEN CURRENT_TIMESTAMP ELSE bookmarks.created END,
    modified = CURRENT_TIMESTAMP,
    deleted = NULL,
    name = @name::TEXT
RETURNING *;

-- name: DeleteBookmark :one
DELETE FROM bookmarks WHERE username = @username::TEXT AND resource_id = @resource_id::UUID
RETURNING *;

-- name: ListBookmarks :many
SELECT * FROM bookmarks b WHERE username = @username::TEXT AND modified > @since::TIMESTAMP;
