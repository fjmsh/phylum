package fs

import (
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f filesystem) ResourceByPath(path string) (Resource, error) {
	if !f.pathRoot.Valid {
		return Resource{}, ErrResourceNotFound
	}
	nodes := goqu.T("nodes").As("n")
	resources := goqu.T("resources").As("r")
	sub := pg.
		Select(resources.Col("id"), resources.Col("parent"), nodes.Col("search"), goqu.L("n.depth + 1")).
		From(resources).
		Join(nodes, goqu.On(resources.Col("parent").Eq(nodes.Col("id")))).
		Where(
			resources.Col("deleted").IsNull(),
			resources.Col("name").Eq(goqu.L("n.search[n.depth + 1]")),
		)

	rec := pg.
		Select(resources.Col("id"), resources.Col("parent"), goqu.L("array_remove(string_to_array(?::TEXT, '/', NULL), '')", path), goqu.L("0")).
		From(resources).
		Where(resources.Col("id").Eq(goqu.V(f.pathRoot))).
		UnionAll(sub)

	l := goqu.T("publinks").As("l")
	q := pg.Select(resources.All(), pg.Select(goqu.L(publinkFieldsQuery)).From(l).Where(l.Col("root").Eq(resources.Col("id")))).
		From(resources).
		WithRecursive("nodes(id, parent, search, depth)", rec).
		Join(nodes, goqu.On(resources.Col("id").Eq(nodes.Col("id")))).
		Where(goqu.L("cardinality(n.search) = n.depth"))

	query, args, _ := q.ToSQL()

	if rows, err := f.db.Query(query, args...); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows, true)
	}
}

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	const query = "SELECT r.*, (SELECT " + publinkFieldsQuery + " FROM publinks l WHERE l.root = r.id) AS links FROM resources r WHERE id = $1::UUID"
	if rows, err := f.db.Query(query, id); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows, true)
	}
}

func (f filesystem) childResourceByName(parentID uuid.UUID, name string) (Resource, error) {
	const query = "SELECT * FROM resources WHERE parent = $1::UUID AND name = $2::TEXT AND deleted IS NULL"
	if rows, err := f.db.Query(query, parentID, name); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows, false)
	}
}

func (f filesystem) ResourceByRootedPath(ref string) (Resource, error) {
	i := strings.Index(ref, ":")

	if i >= 0 {
		if ref[0] == '/' {
			ref = ref[1:]
			i -= 1
		}
		id, err := uuid.Parse(ref[:i])
		if err != nil {
			return Resource{}, ErrResourceNotFound
		}
		f = f.withPathRoot(pgtype.UUID{Bytes: id, Valid: true})
	}
	return f.ResourceByPath(ref[i+1:])
}
