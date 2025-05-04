package fs

import "github.com/jackc/pgx/v5"

func (f filesystem) SharedResources() ([]Resource, error) {
	const q = `SELECT r.*, (SELECT ` + publinkFieldsQuery + ` FROM publinks l WHERE l.root = r.id) as links FROM resources r
WHERE grants ? $1::TEXT
AND deleted IS NULL
AND (grants -> $1::TEXT -> 'p')::INTEGER <> 0
ORDER BY grants -> $1::TEXT -> 't' DESC`
	if rows, err := f.db.Query(q, f.username); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, f.scanLinkedResource)
	}
}
