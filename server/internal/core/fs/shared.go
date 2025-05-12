package fs

import (
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f filesystem) SharedResources(excluded pgtype.UUID) ([]Resource, error) {
	const q = fullResourceQuery + `WHERE r.grants ? @username::TEXT
AND r.id != @excluded::UUID
AND r.deleted IS NULL
AND (r.grants -> @username::TEXT -> 'p')::INTEGER <> 0
ORDER BY r.grants -> @username::TEXT -> 't' DESC`
	args := pgx.NamedArgs{
		"username": f.username,
		"excluded": excluded,
	}
	if rows, err := f.db.Query(q, args); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, f.scanFullResource)
	}
}
