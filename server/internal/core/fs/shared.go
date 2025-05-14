package fs

import (
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f filesystem) SharedResources(excluded pgtype.UUID) ([]Resource, error) {
	const q = fullResourceQuery + `WHERE r.grants ? @user_id::INT
AND r.id != @excluded::UUID
AND r.deleted IS NULL
AND (r.grants -> @user_id::INT -> 'p')::INTEGER <> 0
ORDER BY r.grants -> @user_id::INT -> 't' DESC`
	args := pgx.NamedArgs{
		"user_id":  f.userID,
		"excluded": excluded,
	}
	if rows, err := f.db.Query(q, args); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, f.scanFullResource)
	}
}
