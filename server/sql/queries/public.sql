-- name: GetPublicShare :one
SELECT * FROM public_shares p WHERE name = @name::text AND deleted IS NULL;

-- name: MarkPublicShareAccess :exec
UPDATE public_shares SET accessed = accessed + 1 WHERE id = $1;

-- name: CreatePublicShare :exec
INSERT INTO public_shares(name, created_by, root, password_hash, expires, max_accesses) VALUES(
    @name::text,
    @created_by::text,
    @root::uuid,
    sqlc.narg('password_hash')::text,
    sqlc.narg('expires')::timestamp,
    sqlc.narg('max_accesses')::int
);