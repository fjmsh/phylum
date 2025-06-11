package core

import (
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

func SharedResources(db db.Handler, user User) ([]Resource, error) {
	const q = fullResourceQuery + `WHERE r.grants ? @user_id::INT::TEXT
AND r.id != @user_home::UUID
AND r.deleted IS NULL
AND (r.grants -> @user_id::INT::TEXT -> 'p')::INTEGER <> 0
ORDER BY r.grants -> @user_id::INT::TEXT -> 't' DESC`

	args := pgx.NamedArgs{
		"user_id":   user.ID,
		"user_home": user.Home,
	}
	if rows, err := db.Query(q, args); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanFullResource)
	}
}
