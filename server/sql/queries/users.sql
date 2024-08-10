-- name: CreateUser :one
INSERT INTO users(
    email, created, modified, display_name, password_hash, root, home
) VALUES (
    $1, NOW(), NOW(), $2, $3, $4, $5
) RETURNING *;

-- name: UserByEmail :one
SELECT * from users WHERE email = $1;

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


-- name: UpdateUserRoot :exec
UPDATE users
SET
    root = $1,
    modified = NOW()
WHERE id = $2;

-- name: UpdateUserHome :exec
UPDATE users
SET
    home = $1,
    modified = NOW()
WHERE id = $2;