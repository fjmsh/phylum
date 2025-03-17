-- name: TrashList :many
SELECT * FROM resources
    WHERE CASE
        WHEN sqlc.narg('last_timestamp')::TIMESTAMP IS NULL THEN deleted IS NOT NULL
        ELSE deleted < @last_timestamp::TIMESTAMP OR (deleted = @last_timestamp::TIMESTAMP AND id < @last_id::UUID) END
    AND CASE
        WHEN sqlc.narg('username')::TEXT IS NULL THEN TRUE
        ELSE permissions[@username::TEXT]::integer <> 0 END
    ORDER BY deleted DESC, id DESC
    LIMIT @n::INTEGER;

-- name: TrashSummary :one
SELECT SUM(content_length) AS size, COUNT(*) AS items
    FROM resources
    WHERE deleted IS NOT NULL
    AND CASE
        WHEN sqlc.narg('username')::TEXT IS NULL THEN TRUE
        ELSE permissions[@username::TEXT]::integer <> 0 END;