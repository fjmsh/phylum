-- name: PublicShare :one
SELECT * from public_shares WHERE id = $1;

-- name: AccessPublicShare :exec
UPDATE public_shares SET accesses_left = accesses_left - 1 WHERE id = $1;

-- name: CreatePublicShare :exec
INSERT INTO public_shares(id, created_by, root, password_hash, expires, accesses_left) VALUES(
    @id::text,
    @created_by::text,
    @root::uuid,
    sqlc.narg('password_hash')::text,
    sqlc.narg('expires')::timestamp,
    sqlc.narg('accesses_left')::int
);