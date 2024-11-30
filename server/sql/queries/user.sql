-- name: CreateUser :one
INSERT INTO users(
    username, display_name, password_hash, root, home
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: UserByUsername :one
SELECT username, display_name, password_hash, root, home FROM users WHERE username = $1;

-- name: ListUsers :many
SELECT username, display_name, root, home FROM users WHERE modified > @since::TIMESTAMP;

-- name: UpdateUserDisplayName :exec
UPDATE users
SET
    display_name = $1,
    modified = NOW()
WHERE username = $2;

-- name: UpdateUserPasswordHash :exec
UPDATE users
SET
    password_hash = $1,
    modified = NOW()
WHERE username = $2;

-- name: UpdateUserRoot :exec
UPDATE users
SET
    root = $1,
    modified = NOW()
WHERE username = $2;

-- name: UpdateUserHome :exec
UPDATE users
SET
    home = $1,
    modified = NOW()
WHERE username = $2;
