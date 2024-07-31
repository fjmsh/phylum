-- name: AccessTokenById :one
SELECT * from access_tokens where id = $1;

-- name: InsertAccessToken :one
INSERT INTO access_tokens(
    id, created, expires, username
) VALUES(
    @id::text, NOW(), NOW() + @validity::interval, @username::text
) RETURNING *;
