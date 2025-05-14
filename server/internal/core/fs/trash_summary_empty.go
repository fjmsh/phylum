package fs

import (
	"github.com/doug-martin/goqu/v9"
	"github.com/shroff/phylum/server/internal/core/storage"
)

func (f filesystem) selectDeletedResources() *goqu.SelectDataset {
	q := pg.
		From("resources").
		Where(goqu.C("deleted").IsNotNull())
	if !f.fullAccess {
		q = q.Where(goqu.L("permissions[?]::INTEGER <> 0", f.userID))
	}
	return q
}

func (f filesystem) TrashSummary() (int, int, error) {
	q := f.selectDeletedResources().
		Select(
			goqu.COALESCE(goqu.SUM("content_length"), 0),
			goqu.COUNT("*"))

	query, args, _ := q.ToSQL()
	row := f.db.QueryRow(query, args...)
	var size int
	var items int
	err := row.Scan(&size, &items)
	return items, size, err
}

func (f filesystem) TrashEmpty() (int, error) {
	q := f.selectDeletedResources().
		Delete().
		Returning("id", "dir")
	query, args, _ := q.ToSQL()
	count, ids, err := collectNonDirResourceIDs(f.db.Query(query, args...))
	storage.Get().DeleteAll(ids)
	return count, err
}
