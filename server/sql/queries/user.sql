-- name: SharedResources :many
SELECT * FROM resources
    WHERE grants ? @username::TEXT
    AND id <> @user_home::UUID
    AND deleted IS NULL
    AND grants -> @username::TEXT -> 'p' <> 0
    ORDER BY grants -> @username::TEXT -> 't' DESC;
