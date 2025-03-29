-- name: CreateUser :one
INSERT INTO users(
    username, display_name, password_hash, root, home
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: UserByUsername :one
SELECT username, display_name, password_hash, root, home, permissions FROM users WHERE username = $1;

-- name: ListUsers :many
SELECT username, display_name, root, home FROM users WHERE modified > @since::TIMESTAMP;

-- name: UpdateUserPasswordHash :exec
UPDATE users
SET
    password_hash = $1,
    modified = NOW()
WHERE username = $2;

-- name: SharedResources :many
SELECT * FROM resources
    WHERE grants ? @username::TEXT
    AND id <> @user_home::UUID
    AND deleted IS NULL
    AND grants -> @username::TEXT -> 'p' <> 0
    ORDER BY grants -> @username::TEXT -> 't' DESC;
