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

-- name: GrantUserPermissions :exec
UPDATE users
SET
    permissions = permissions | $1,
    modified = NOW()
WHERE username = $2;

-- Cannot manage to put a named parameter for $1. Something like 'mask' would be less confusion
-- name: RevokeUserPermissions :exec
UPDATE users
SET
    permissions = permissions & $1,
    modified = NOW()
WHERE username = $2;

-- name: SharedResources :many
SELECT r.*
FROM permissions p
JOIN resources r
ON p.resource_id = r.id
WHERE p.username = @username::text
AND p.resource_id <> @user_home::uuid
AND p.value <> 0
AND r.deleted IS NULL
ORDER BY p.modified DESC;