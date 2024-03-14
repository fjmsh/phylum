-- name: AllStorageBackends :many
SELECT * from storage_backends;

-- name: CreateStorageBackend :exec
INSERT INTO storage_backends(
    name, driver, params
) VALUES(
    $1, $2, $3
);