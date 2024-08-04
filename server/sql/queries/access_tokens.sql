-- name: AccessTokenById :one
SELECT * from access_tokens where id = $1;

-- name: InsertAccessToken :one
INSERT INTO access_tokens(
    id, created, expires, user_id
) VALUES(
    @id::text, NOW(), NOW() + @validity::interval, @user_id::int
) RETURNING *;
