-- name: AccessTokenById :one
SELECT * FROM access_tokens t JOIN users u ON t.username = u.username WHERE t.id = $1;

-- name: InsertAccessToken :one
INSERT INTO access_tokens(
    id, expires, username
) VALUES(
    @id::text, NOW() + @validity::interval, @username::text
) RETURNING *;
