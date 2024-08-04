-- name: SiloById :one
SELECT * from silos where id = $1;

-- name: SiloByName :one
SELECT * from silos where name = $1;

-- name: DeleteSilo :exec
DELETE from silos where id = $1;

-- name: CreateSilo :exec
INSERT INTO silos(
    id, created, modified, owner, name, storage
) VALUES(
    $1, NOW(), NOW(), $2, $3, $4
);

-- name: ListAllSilos :many
SELECT * from silos;

-- name: ListSilosForUser :many
SELECT * from silos where owner = @user_id::int;