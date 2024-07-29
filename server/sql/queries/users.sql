-- name: CreateUser :exec
INSERT INTO users(
    username, display_name, password_hash
) VALUES (
    $1, $2, $3
);

-- name: UserByUsername :one
SELECT * from users WHERE username = $1;

-- name: ListUsers :many
SELECT * from users WHERE deleted IS NULL;