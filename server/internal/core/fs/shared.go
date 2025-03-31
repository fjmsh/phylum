package fs

import "github.com/jackc/pgx/v5"

func (f filesystem) SharedResources() ([]Resource, error) {
	const q = `SELECT * FROM resources
WHERE grants ? $1::TEXT
AND id <> $2::UUID
AND deleted IS NULL
AND grants -> $1::TEXT -> 'p' <> 0
ORDER BY grants -> $1::TEXT -> 't' DESC`
	if rows, err := f.db.Query(f.ctx, q, f.username); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, f.scanResource)
	}
}
