package core

import (
	"slices"
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

const fullResourceQuery = `SELECT r.*,
COALESCE(v.versions, '[]'::JSONB) AS versions,
COALESCE(l.publinks, '[]'::JSONB) AS links,
COALESCE(p.permissions, '{}'::JSONB) AS inherited_permissions,
a.ancestors AS ancestors
FROM resources r
LEFT JOIN resource_versions_json v ON r.id = v.id
LEFT JOIN resource_publinks_json l ON r.id = l.id
LEFT JOIN resources p ON p.id = r.parent
LEFT JOIN resource_ancestors a on r.id = a.id
`

const simpleResourceQuery = `SELECT r.*,
COALESCE(v.versions, '[]'::JSONB) AS versions,
COALESCE(l.publinks, '[]'::JSONB) AS links,
FROM resources r
LEFT JOIN resource_versions_json v ON r.id = v.id
LEFT JOIN resource_publinks_json l ON r.id = l.id
`

func selectResourceTree(id uuid.UUID, includeDeleted bool, extraCols ...string) (exp.AliasedExpression, *goqu.SelectDataset) {
	r := goqu.T("resources").As("r")
	n := goqu.T("nodes").As("n")
	rec := pg.From(r).
		Select(r.Col("id"), r.Col("parent"), r.Col("deleted"), goqu.L("? + 1", n.Col("depth")))
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

	q := pg.
		From(n).
		WithRecursive("nodes("+strings.Join(cols, ",")+")", base.UnionAll(rec))
	return n, q
}

func selectResources(q *goqu.SelectDataset, n exp.AliasedExpression) (*goqu.SelectDataset, exp.AliasedExpression) {
	r := goqu.T("resources").As("r")
	v := goqu.T("resource_versions_json").As("v")
	l := goqu.T("resource_publinks_json").As("l")
	q = q.From(r).
		Join(n, goqu.On(r.Col("id").Eq(n.Col("id")))).
		LeftJoin(v, goqu.On(r.Col("id").Eq(v.Col("id")))).
		Select(
			r.All(),
			goqu.L("COALESCE(?, '[]'::JSONB)", v.Col("versions")),
			goqu.L("COALESCE(?, '[]'::JSONB)", l.Col("publinks")),
		)
	return q, r
}

func selectDirectChildren(id uuid.UUID, deleted pgtype.Timestamp, includeDeleted bool) (exp.AliasedExpression, *goqu.SelectDataset) {
	r := goqu.T("resources").As("r")
	v := goqu.T("resource_versions_json").As("v")
	l := goqu.T("resource_publinks_json").As("l")
	q := pg.
		From(r).
		LeftJoin(v, goqu.On(r.Col("id").Eq(v.Col("id")))).
		LeftJoin(l, goqu.On(r.Col("id").Eq(l.Col("id")))).
		Select(
			r.All(),
			goqu.L("COALESCE(?, '[]'::JSONB)", v.Col("versions")),
			goqu.L("COALESCE(?, '[]'::JSONB)", l.Col("publinks")),
		).
		Where(r.Col("parent").Eq(goqu.V(id)))
	if !includeDeleted {
		q = q.Where(goqu.L("? IS NOT DISTINCT FROM ?", r.Col("deleted"), goqu.V(deleted)))
	}

	return r, q
}
