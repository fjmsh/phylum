-- name: AccessTokenById :one
SELECT * FROM access_tokens t JOIN users u ON t.user_id = u.id WHERE t.id = $1;

-- name: InsertAccessToken :one
INSERT INTO access_tokens(
    id, created, expires, user_id
) VALUES(
    @id::text, NOW(), NOW() + @validity::interval, @user_id::int
) RETURNING *;
