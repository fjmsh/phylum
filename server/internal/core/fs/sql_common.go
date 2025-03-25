package fs

import (
	"encoding/json"
	"slices"
	"strings"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/api/serve"
)

type tbl interface {
	Col(interface{}) exp.IdentifierExpression
	All() exp.IdentifierExpression
}

func selectResourceTree(id uuid.UUID, excludeTreeRoot, includeDeleted bool, cols ...string) (exp.AliasedExpression, *goqu.SelectDataset) {
	n := goqu.T("nodes").As("n")
	r := goqu.T("resources").As("r")
	rec := pg.From(r).
		Select(r.Col("id"), r.Col("parent"), r.Col("deleted"), goqu.L("? + 1", goqu.I("n.depth")))
	if len(cols) != 0 {
		s := make([]interface{}, len(cols))
		for i, c := range cols {
			s[i] = r.Col(c)
		}
		rec = rec.SelectAppend(s...)
	}
	rec = rec.Join(n, goqu.On(r.Col("parent").Eq(n.Col("id"))))

	if !includeDeleted {
		rec = rec.Where(goqu.L("? IS NOT DISTINCT FROM ?", r.Col("deleted"), n.Col("deleted")))
	}

	base := pg.From(r).
		Select(r.Col("id"), r.Col("parent"), r.Col("deleted"), goqu.L("0"))
	if len(cols) != 0 {
		s := make([]interface{}, len(cols))
		for i, c := range cols {
			s[i] = r.Col(c)
		}
		base = base.SelectAppend(s...)
	}

	c := []string{"id", "parent", "deleted", "depth"}
	c = slices.Insert(c, 4, cols...)
	cs := strings.Join(c, ",")

	q := pg.
		From(n).
		WithRecursive("nodes("+cs+")",
			base.Where(r.Col("id").Eq(id)).
				UnionAll(rec))
	if excludeTreeRoot {
		q = q.Where(n.Col("depth").Gt(0))
	}
	return n, q
}

func selectDirectChildren(id uuid.UUID, deleted *time.Time) (tbl, *goqu.SelectDataset) {
	r := goqu.T("resources").As("r")
	q := pg.
		From(r).
		Where(r.Col("parent").Eq(goqu.V(id))).
		Where(goqu.L("? IS NOT DISTINCT FROM ?", r.Col("deleted"), goqu.V(deleted)))

	return r, q
}

func (f filesystem) collectResource(rows pgx.Rows) (Resource, error) {
	if r, err := pgx.CollectExactlyOneRow(rows, f.scanResource); err == nil {
		return r, nil
	} else {
		if err == pgx.ErrNoRows {
			err = ErrResourceNotFound
		}
		return r, err
	}

}

func (f filesystem) scanServeResource(row pgx.CollectableRow) (serve.Resource, error) {
	return f.scanResource(row)
}

func (f filesystem) scanResource(row pgx.CollectableRow) (Resource, error) {
	r := Resource{f: f}
	err := row.Scan(
		&r.id,
		&r.name,
		&r.parentID,
		&r.dir,
		&r.created,
		&r.modified,
		&r.deleted,
		&r.contentLength,
		&r.contentType,
		&r.contentSHA256,
		&r.permissions,
		&r.grants,
	)
	if err != nil {
		return r, err
	}
	permission := Permission(0)
	if f.fullAccess {
		permission = -1
	} else if p, err := readPermissionFromJson(r.permissions, f.username); err != nil {
		return Resource{}, err
	} else {
		permission = p
	}
	if permission&PermissionRead == 0 {
		return Resource{}, ErrResourceNotFound
	}
	r.userPermission = permission
	return r, err
}

func readPermissionFromJson(j []byte, username string) (Permission, error) {
	if j == nil {
		return PermissionNone, nil
	}
	p := make(map[string]Permission)
	err := json.Unmarshal(j, &p)
	if err != nil {
		return PermissionNone, err
	}
	if p, ok := p[username]; ok {
		return p, nil
	}
	return PermissionNone, nil
}

func collectNonDirResourceIDs(rows pgx.Rows, e error) (total int, ids []uuid.UUID, err error) {
	if e != nil {
		return 0, nil, e
	}
	defer rows.Close()
	var id uuid.UUID
	var dir bool
	for rows.Next() {
		if err := rows.Scan(&id, &dir); err != nil {
			return total, nil, err
		}
		if !dir {
			ids = append(ids, id)
		}
		total++
	}
	err = rows.Err()
	return total, ids, err
}
