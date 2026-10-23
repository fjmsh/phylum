package core

import (
	"slices"
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

const publinksQuery = "COALESCE(JSONB_AGG(JSONB_BUILD_OBJECT(" +
	"'id',l.id," +
	"'expires',EXTRACT(EPOCH FROM l.expires)::integer," +
	"'protected',l.password_hash <> ''," +
	"'access_limit',l.access_limit," +
	"'accessed',l.accessed" +
	")), '[]'::JSONB)"

const fullResourceQuery = `SELECT r.*,
COALESCE(v.versions, '[]'::JSONB) AS versions,
(SELECT ` + publinksQuery + ` FROM publinks l WHERE l.root = r.id) AS links,
CASE WHEN COALESCE(p.permissions[@user_id::INT]::INTEGER, 0) <> 0 THEN p.id ELSE NULL END AS visible_parent,
COALESCE(p.permissions, '{}'::JSONB) AS inherited_permissions
FROM resources r
LEFT JOIN resources p ON p.id = r.parent
LEFT JOIN resource_versions_json v ON r.id = v.id
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
	l := goqu.T("publinks").As("l")
	q = q.From(r).
		Join(n, goqu.On(r.Col("id").Eq(n.Col("id")))).
		LeftJoin(v, goqu.On(r.Col("id").Eq(v.Col("id")))).
		Select(
			r.All(),
			goqu.L("COALESCE(?, '[]'::JSONB)", v.Col("versions")),
			pg.Select(goqu.L(publinksQuery)).From(l).Where(l.Col("root").Eq(r.Col("id"))),
		)
	return q, r
}

func selectDirectChildren(id uuid.UUID, deleted pgtype.Timestamp, includeDeleted bool) (exp.AliasedExpression, *goqu.SelectDataset) {
	v := goqu.T("resource_versions_json").As("v")
	l := goqu.T("publinks").As("l")
	r := goqu.T("resources").As("r")
	q := pg.
		From(r).
		LeftJoin(v, goqu.On(r.Col("id").Eq(v.Col("id")))).
		Select(
			r.All(),
			goqu.L("COALESCE(?, '[]'::JSONB)", v.Col("versions")),
			pg.Select(goqu.L(publinksQuery)).From(l).Where(l.Col("root").Eq(r.Col("id"))),
		).
		Where(r.Col("parent").Eq(goqu.V(id)))
	if !includeDeleted {
		q = q.Where(goqu.L("? IS NOT DISTINCT FROM ?", r.Col("deleted"), goqu.V(deleted)))
	}

	return r, q
}
