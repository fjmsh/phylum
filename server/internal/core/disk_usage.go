package core

import (
	"github.com/doug-martin/goqu/v9"
)

type DiskUsageInfo struct {
	TotalSize int64
	Entities  int64
	Files     int64
	Dirs      int64
}

func (f filesystem) DiskUsage(r Resource) (DiskUsageInfo, error) {
	// TODO: #versions This is broken
	n, q := selectResourceTree(r.id, false, "content_length", "dir")

	q = q.
		Select(
			goqu.SUM(n.Col("content_length")),
			goqu.COUNT("*"),
			goqu.L("COUNT(CASE ? WHEN TRUE THEN 1 ELSE NULL END)", n.Col("dir")))

	query, args, _ := q.ToSQL()

	row := f.db.QueryRow(query, args...)
	var size, count, dirs int64
	err := row.Scan(&size, &count, &dirs)

	return DiskUsageInfo{
		TotalSize: size,
		Entities:  count,
		Files:     count - dirs,
		Dirs:      dirs,
	}, err
}
