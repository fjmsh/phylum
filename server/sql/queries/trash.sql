-- name: TrashCompact :many
DELETE FROM resources WHERE deleted < @t::TIMESTAMP RETURNING id, dir;

-- name: RestoreDeleted :many
WITH RECURSIVE nodes(id, parent, ts) AS (
    SELECT r.id, r.parent, r.deleted
        FROM resources r
        WHERE r.id = @resource_id::UUID
        AND CASE
            WHEN sqlc.narg('username')::TEXT IS NULL THEN TRUE
            ELSE permissions[@username::TEXT]::integer <> 0 END
    UNION ALL
        SELECT r.id, r.parent, n.ts
            FROM resources r
            JOIN nodes n ON r.parent = n.id
            WHERE r.deleted = n.ts
)
UPDATE resources
    SET modified = NOW(), deleted = NULL
    FROM nodes
    WHERE resources.id = nodes.id
    RETURNING resources.content_length;

SELECT r.*
    FROM nodes n
    JOIN resources r
        ON n.id = r.id
    WHERE n.depth >= @min_depth::INTEGER;

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
SELECT COALESCE(SUM(content_length), 0)::INTEGER AS size, COUNT(*) AS items
    FROM resources
    WHERE deleted IS NOT NULL
    AND CASE
        WHEN sqlc.narg('username')::TEXT IS NULL THEN TRUE
        ELSE permissions[@username::TEXT]::integer <> 0 END;