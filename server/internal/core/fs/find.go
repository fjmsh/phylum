package fs

import (
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	const query = "SELECT r.*, (SELECT " + publinkFieldsQuery + " FROM publinks l WHERE l.root = r.id) AS links FROM resources r WHERE id = $1::UUID"
	if rows, err := f.db.Query(query, id); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows, true)
	}
}

// ResourceByPathWithRoot returns the resource at a given path from an optionally specified root.
// The "<uuid>: prefix can be used to specify the path root.
// Will default to using the filesystem's current path root if one is not specified.
// An empty path or "/" will return the root resource.
func (f filesystem) ResourceByPathWithRoot(path string) (Resource, error) {
	id, path, err := parseUUIDPrefix(path)
	if err != nil {
		return Resource{}, ErrResourceNotFound
	}
	if id.Valid {
		f = f.withPathRoot(id)
	}
	return f.ResourceByPath(path)
}

// ResourceByPath returns the resource at a given path from this filesystem's path root
// An empty path or "/" will return the root resource.
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

// targetNameParentByPathWithRoot returns the target resource name and its parent
// Optionally allows you to specify a root using a "<uuid>:" prefix
// If no uuid prefix is supplied then uses r as the pathRoot if the path is not absolute (does not begin with '/')
// If no uuid prefix is supplied and the path begins with '/' then r.f is used as the path root
// Splits the path to extract its last component as the name and traverses the rest of the path from the root as the parent
// If no name is specified then return r.name as the name
func (r Resource) targetNameParentByPathWithRoot(path string) (string, Resource, error) {
	return r.f.targetNameParentByPathWithRoot(path, r)
}

func (f filesystem) targetNameParentByPathWithRoot(path string, src Resource) (string, Resource, error) {
	id, path, err := parseUUIDPrefix(path)
	if err != nil {
		return "", Resource{}, err
	}
	if id.Valid {
		f = f.withPathRoot(id)
	} else if len(path) == 0 {
		return "", Resource{}, ErrResourceNameInvalid
	} else if path[0] != '/' && src.id != uuid.Nil {
		f = f.withPathRoot(pgtype.UUID{Bytes: src.id, Valid: true})
	}

	i := strings.LastIndex(strings.TrimRight(path, "/"), "/")
	parentPath := ""
	if i > 0 {
		parentPath = path[i:]
	}
	parent, err := f.ResourceByPath(parentPath)
	if err != nil {
		return "", Resource{}, err
	}
	name := path[i+1:]
	if name == "" {
		name = src.name
	}
	return name, parent, nil
}

func (f filesystem) childResourceByName(parentID uuid.UUID, name string) (Resource, error) {
	const query = "SELECT * FROM resources WHERE parent = $1::UUID AND name = $2::TEXT AND deleted IS NULL"
	if rows, err := f.db.Query(query, parentID, name); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows, false)
	}
}

func parseUUIDPrefix(path string) (pgtype.UUID, string, error) {
	i := strings.Index(path, ":")
	si := strings.Index(path, "/")

	// Ignore ':' after '/'
	if i >= 0 && (si < 0 || si > i) {
		id, err := uuid.Parse(path[:i])
		return pgtype.UUID{Bytes: id, Valid: true}, path[i+1:], err
	}
	return pgtype.UUID{}, path, nil
}
