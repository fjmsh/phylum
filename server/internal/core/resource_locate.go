package core

import (
	"strings"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	const query = fullResourceQuery + "WHERE r.id = @id::UUID"
	args := pgx.NamedArgs{
		"user_id": f.userID,
		"id":      id,
	}
	if rows, err := f.db.Query(query, args); err != nil {
		return Resource{}, err
	} else {
		return f.collectFullResource(rows)
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
	r := goqu.T("resources").As("r")
	p := goqu.T("resources").As("p")
	sub := pg.
		Select(r.Col("id"), r.Col("parent"), nodes.Col("search"), goqu.L("n.depth + 1")).
		From(r).
		Join(nodes, goqu.On(r.Col("parent").Eq(nodes.Col("id")))).
		Where(
			r.Col("deleted").IsNull(),
			r.Col("name").Eq(goqu.L("n.search[n.depth + 1]")),
		)

	rec := pg.
		Select(r.Col("id"), r.Col("parent"), goqu.L("array_remove(string_to_array(?::TEXT, '/', NULL), '')", path), goqu.L("0")).
		From(r).
		Where(r.Col("id").Eq(goqu.V(f.pathRoot))).
		UnionAll(sub)

	l := goqu.T("publinks").As("l")
	v := goqu.T("resource_versions").As("v")
	q := pg.Select(r.All(),
		pg.Select(goqu.L(versionsQuery)).From(v).Where(v.Col("resource_id").Eq(r.Col("id"))),
		pg.Select(goqu.L(publinksQuery)).From(l).Where(l.Col("root").Eq(r.Col("id"))),
		pg.Select(goqu.L("CASE WHEN COALESCE(p.permissions[?::INT]::INTEGER, 0) <> 0 THEN p.id ELSE NULL END AS visible_parent", f.userID)),
		pg.Select(goqu.L("COALESCE(p.permissions, '{}'::JSONB)")),
	).
		From(r).
		LeftJoin(goqu.T("resources").As("p"), goqu.On(p.Col("id").Eq(r.Col("parent")))).
		WithRecursive("nodes(id, parent, search, depth)", rec).
		Join(nodes, goqu.On(r.Col("id").Eq(nodes.Col("id")))).
		Where(goqu.L("cardinality(n.search) = n.depth"))

	query, args, _ := q.ToSQL()

	if rows, err := f.db.Query(query, args...); err != nil {
		return Resource{}, err
	} else {
		return f.collectFullResource(rows)
	}
}

// targetNameParentByPathWithRoot returns the target resource name and its parent
// Optionally allows you to specify a root using a "<uuid>:" prefix
// If no uuid prefix is supplied then uses r as the pathRoot if the path is not absolute (does not begin with '/')
// If no uuid prefix is supplied and the path begins with '/' then r.f is used as the path root
// Splits the path to extract its last component as the name and traverses the rest of the path from the root as the parent
// If no name is specified then return r.name as the name
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

	path = strings.TrimRight(path, "/")
	i := strings.LastIndex(path, "/")
	parentPath := ""
	if i > 0 {
		parentPath = path[:i]
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
	const query = fullResourceQuery + "WHERE r.parent = @parent::UUID AND r.name = @name::TEXT AND r.deleted IS NULL"
	args := pgx.NamedArgs{
		"user_id": f.userID,
		"parent":  parentID,
		"name":    name,
	}
	if rows, err := f.db.Query(query, args); err != nil {
		return Resource{}, err
	} else {
		return f.collectFullResource(rows)
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

func (f filesystem) FindVersion(r Resource, versionID uuid.UUID) (Version, error) {
	if versionID == uuid.Nil {
		versionID = r.latestVersionInfo.ID
	}

	const q = `SELECT id, created, size, mime_type, sha256, storage FROM resource_versions
	WHERE resource_id = $1::UUID
	AND id = $2::UUID
	AND DELETED IS NULL`

	row := f.db.QueryRow(q, r.id, versionID)
	var v Version
	var created time.Time
	err := row.Scan(&v.ID, &created, &v.Size, &v.MimeType, &v.SHA256, &v.Storage)
	if err != nil {
		if Is(err, pgx.ErrNoRows) {
			err = ErrVersionNotFound
		}
		return v, err
	}
	v.Created = int(created.Unix())
	return v, nil
}
