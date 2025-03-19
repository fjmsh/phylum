-- name: Search :many
SELECT *
    FROM resources
    WHERE deleted IS NULL
    AND f_prepare_search(name) %> @search::TEXT
    AND CASE
        WHEN sqlc.narg('username')::TEXT IS NULL THEN TRUE
        ELSE permissions[@username::TEXT]::integer <> 0 END
    ORDER BY word_similarity(f_prepare_search(name), @search::TEXT) DESC;