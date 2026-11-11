package core

import (
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

func SharedResources(db db.Handler, userID int32, userFilesPrivilege ResourcePermission) ([]Resource, error) {
	const q = simpleResourceQuery + `WHERE (r.grants ? @user_id::INT::TEXT OR r.grants ? '0')
AND r.id != (SELECT home FROM users WHERE id = @user_id::INT)
AND r.deleted IS NULL
AND (r.grants -> @user_id::INT::TEXT -> 'p')::INTEGER <> 0
ORDER BY GREATEST(COALESCE(grants -> '3' -> 't', '0'), COALESCE(grants -> '2' -> 't', '0')) DESC`

	args := pgx.NamedArgs{
		"user_id":              userID,
		"user_files_privilege": userFilesPrivilege,
	}
	if rows, err := db.Query(q, args); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanSimpleResource)
	}
}
