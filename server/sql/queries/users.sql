-- name: CreateUser :one
INSERT INTO users(
    username, created, modified, display_name, password_hash, root, home
) VALUES (
    $1, NOW(), NOW(), $2, $3, $4, $5
) RETURNING *;

-- name: UserByUsername :one
SELECT * from users WHERE username = $1;

-- name: UserByID :one
SELECT * from users WHERE id = $1;

-- name: ListUsers :many
SELECT * from users WHERE deleted IS NULL;

-- name: UpdateUserDisplayName :exec
UPDATE users
SET
    display_name = $1,
    modified = NOW()
WHERE id = $2;

-- name: UpdateUserPasswordHash :exec
UPDATE users
SET
    password_hash = $1,
    modified = NOW()
WHERE id = $2;


-- name: UpdateUserDirs :exec
UPDATE users
SET
    root = $1,
    home = $2,
    modified = NOW()
WHERE id = $3;