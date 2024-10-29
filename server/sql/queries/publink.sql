-- name: GetPublink :one
SELECT * FROM publinks p WHERE name = @name::text AND deleted IS NULL;

-- name: MarkPublinkAccess :exec
UPDATE publinks SET accessed = accessed + 1 WHERE id = $1;

-- name: CreatePublink :exec
INSERT INTO publinks(name, created_by, root, password_hash, expires, max_accesses) VALUES(
    @name::text,
    @created_by::text,
    @root::uuid,
    sqlc.narg('password_hash')::text,
    sqlc.narg('expires')::timestamp,
    sqlc.narg('max_accesses')::int
);