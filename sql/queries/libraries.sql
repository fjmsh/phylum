-- name: LibraryById :one
SELECT * from libraries where id = $1;

-- name: CreateLibrary :exec
INSERT INTO libraries(
    id, owner, display_name
) VALUES(
    $1, $2, $3
);