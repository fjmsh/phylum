package fs

import (
	"slices"
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

const publinkFieldsQuery = "COALESCE(JSONB_AGG(JSONB_BUILD_OBJECT(" +
	"'id',l.id," +
	"'expires',EXTRACT(EPOCH FROM l.expires)::integer," +
	"'protected',l.password_hash <> ''," +
	"'access_limit',l.access_limit," +
	"'accessed',l.accessed)), '[]'::JSONB)"

const fullResourceQuery = `SELECT r.*,
(SELECT ` + publinkFieldsQuery + ` FROM publinks l WHERE l.root = r.id) AS links,
CASE WHEN COALESCE(p.permissions[@user_id::INT]::INTEGER, 0) <> 0 THEN p.id ELSE NULL END AS visible_parent,
COALESCE(p.permissions, '{}'::JSONB) AS inherited_permissions
FROM resources r LEFT JOIN resources p ON p.id = r.parent
`

func selectResourceTree(id uuid.UUID, excludeTreeRoot, includeDeleted, includeLinks bool, extraCols ...string) (exp.IdentifierExpression, exp.AliasedExpression, *goqu.SelectDataset) {
	t := goqu.T("resources")
	r := t.As("r")
	n := goqu.T("nodes").As("n")
	rec := pg.From(r).
		Select(r.Col("id"), r.Col("parent"), r.Col("deleted"), goqu.L("? + 1", goqu.I("n.depth")))
	if len(extraCols) != 0 {
		s := make([]interface{}, len(extraCols))
		for i, c := range extraCols {
			s[i] = r.Col(c)
		}
		rec = rec.SelectAppend(s...)
	}
	rec = rec.Join(n, goqu.On(r.Col("parent").Eq(n.Col("id"))))

	if !includeDeleted {
		rec = rec.Where(goqu.L("? IS NOT DISTINCT FROM ?", r.Col("deleted"), n.Col("deleted")))
	}

	base := pg.
		From(r).
		Select(r.Col("id"), r.Col("parent"), r.Col("deleted"), goqu.L("0")).
		Where(r.Col("id").Eq(id))

	if len(extraCols) != 0 {
		s := make([]interface{}, len(extraCols))
		for i, c := range extraCols {
			s[i] = r.Col(c)
		}
		base = base.SelectAppend(s...)
	}

	cols := []string{"id", "parent", "deleted", "depth"}
	cols = slices.Insert(cols, 4, extraCols...)
	idSelect := pg.From(n).Select(n.Col("id"))
	if excludeTreeRoot {
		idSelect = idSelect.Where(n.Col("depth").Gt(0))
	}

	l := goqu.T("publinks").As("l")
	q := pg.
		From(t)
	if includeLinks {
		q = q.Select(t.All(), pg.Select(goqu.L(publinkFieldsQuery)).From(l).Where(l.Col("root").Eq(t.Col("id"))))
	}
	q = q.WithRecursive("nodes("+strings.Join(cols, ",")+")", base.UnionAll(rec)).
		Where(t.Col("id").Eq(idSelect))
	return t, n, q
}

func selectDirectChildren(id uuid.UUID, deleted pgtype.Timestamp, includeDeleted bool) (exp.AliasedExpression, *goqu.SelectDataset) {
	l := goqu.T("publinks").As("l")
	r := goqu.T("resources").As("r")
	q := pg.
		From(r).
		Select(r.All(), pg.Select(goqu.L(publinkFieldsQuery)).From(l).Where(l.Col("root").Eq(r.Col("id")))).
		Where(r.Col("parent").Eq(goqu.V(id)))
	if !includeDeleted {
		q = q.Where(goqu.L("? IS NOT DISTINCT FROM ?", r.Col("deleted"), goqu.V(deleted)))
	}

	return r, q
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
