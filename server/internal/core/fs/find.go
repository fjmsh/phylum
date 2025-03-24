package fs

import (
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
)

func (f filesystem) ResourceByPath(path string) (Resource, error) {
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
		Where(resources.Col("id").Eq(goqu.V(f.rootID))).
		UnionAll(sub)

	q := pg.Select(resources.All()).
		From(resources).
		WithRecursive("nodes(id, parent, search, depth)", rec).
		Join(nodes, goqu.On(resources.Col("id").Eq(nodes.Col("id")))).
		Where(goqu.L("cardinality(n.search) = n.depth"))

	query, args, _ := q.ToSQL()

	if rows, err := f.db.Query(f.ctx, query, args...); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows)
	}
}

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	const query = "SELECT * FROM resources WHERE id = $1::UUID"
	if rows, err := f.db.Query(f.ctx, query, id); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows)
	}
}

func (f filesystem) ChildResourceByName(parentID uuid.UUID, name string) (Resource, error) {
	const query = "SELECT * FROM resources WHERE parent = $1::UUID AND name = $2::TEXT AND deleted IS NULL"
	if rows, err := f.db.Query(f.ctx, query, parentID, name); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows)
	}
}

func (f filesystem) ResourceByPathOrUUID(pathOrUUID string) (Resource, error) {
	if pathOrUUID == "" {
		return Resource{}, ErrResourcePathInvalid
	}
	if pathOrUUID[0] == '/' {
		return f.ResourceByPath(pathOrUUID)
	}
	if id, err := uuid.Parse(pathOrUUID); err != nil {
		return Resource{}, err
	} else {
		return f.ResourceByID(id)
	}
}
