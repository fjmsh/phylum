-- name: PublicShare :one
SELECT * from public_shares WHERE id = $1;

-- name: AccessPublicShare :exec
UPDATE public_shares SET accesses_left = accesses_left - 1 WHERE id = $1;
