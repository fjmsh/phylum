-- name: CreateUser :one
INSERT INTO users(
    display_name, username, password_hash
) VALUES (
    $1, $2, $3
)
RETURNING *;


-- name: UserByUsername :one
SELECT * from users WHERE username = $1;