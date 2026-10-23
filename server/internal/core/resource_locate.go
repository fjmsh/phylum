package core

import (
	"errors"
	"fmt"
	"path"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f *FileSystem) ResourceByID(id uuid.UUID) (Resource, error) {
	if r, err := resourceByID(f.db, id, f.userID, f.userFilesPrivilege); err != nil {
		return Resource{}, err
	} else if _, err := f.checkPermission(r, ResourcePermissionRead); err != nil {
		return Resource{}, err
	} else {
		return r, nil
	}
}

func resourceByID(db db.Handler, id uuid.UUID, userID int32, userFilesPrivilege ResourcePermission) (Resource, error) {
	query := fullResourceQuery + "\nWHERE r.id = @id::UUID"
	args := pgx.NamedArgs{
		"user_id":              userID,
		"user_files_privilege": userFilesPrivilege,
		"id":                   id,
	}
	if rows, err := db.Query(query, args); err != nil {
		return Resource{}, err
	} else {
		return collectFullResource(rows)
	}
}

// ResourceByPathWithRoot locates the resource at [path]. [path] may begin with
// a "<uuid>:" prefix, which will traverse the path relative to that root
// instead of this [FileSystem]'s default [PathRoot].
//
// An empty path or "/" will return the root resource.
//
// A permission check will be performed to ensure that the [FileSystem]'s [User]
// has read permissions on the resource. If not, then [ErrResourceNotFound] will
// be returned.
func (f *FileSystem) ResourceByPathWithRoot(path string) (Resource, error) {
	parsedID, path, err := parseUUIDPrefix(path)
	if err != nil {
		return Resource{}, ErrResourceNotFound
	}
	if parsedID.Valid {
		f = f.withPathRoot(parsedID)
	}
	return f.ResourceByPath(path)
}

// ResourceByPath locates the resource at [path].
//
// An empty path or "/" will return the root resource.
//
// A permission check will be performed to ensure that the [FileSystem]'s [User]
// has read permissions on the resource. If not, then [ErrResourceNotFound] will
// be returned.
func (f *FileSystem) ResourceByPath(path string) (Resource, error) {
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
		Where(r.Col("id").Eq(goqu.V(f.pathRoot.String()))).
		UnionAll(sub)

	v := goqu.T("resource_versions_json").As("v")
	l := goqu.T("resource_publinks_json").As("l")
	q := pg.Select(r.All(),
		goqu.L("COALESCE(?, '[]'::JSONB)", v.Col("versions")),
		goqu.L("COALESCE(?, '[]'::JSONB)", l.Col("publinks")),
		pg.Select(goqu.L("CASE WHEN (COALESCE(p.permissions[?::INT]::INTEGER, 0) | ?::INT) <> 0 THEN p.id ELSE NULL END AS visible_parent", f.userID, f.userFilesPrivilege)),
		pg.Select(goqu.L("COALESCE(p.permissions, '{}'::JSONB)")),
	).
		From(r).
		LeftJoin(goqu.T("resources").As("p"), goqu.On(p.Col("id").Eq(r.Col("parent")))).
		WithRecursive("nodes(id, parent, search, depth)", rec).
		Join(nodes, goqu.On(r.Col("id").Eq(nodes.Col("id")))).
		LeftJoin(v, goqu.On(r.Col("id").Eq(v.Col("id")))).
		LeftJoin(l, goqu.On(r.Col("id").Eq(l.Col("id")))).
		Where(goqu.L("cardinality(n.search) = n.depth"))

	query, args, _ := q.ToSQL()

	if rows, err := f.db.Query(query, args...); err != nil {
		return Resource{}, err
	} else if r, err := collectFullResource(rows); err != nil {
		return Resource{}, err
	} else if _, err := f.checkPermission(r, ResourcePermissionRead); err != nil {
		return Resource{}, err
	} else {
		return r, nil
	}
}

// targetByPathWithRoot extracts the [name] and [parent] resource of from
// the given [path].
//
// Uses the last segment of [path] as the [name] and traverses the previous
// segments to locate [parent]. If [path] has no segments then [src].[name]
// is used as the [name] instead.
//
// If [path] begins with a "<uuid>:", then the path traversed is relative to
// that root.
//
// If [path] does not begin with a "<uuid>:" prefix, and is absolute (begins
// with '/') then the path traversed is relative to [f].[pathRoot]
//
// If [path] does not begin with a "<uuid>:" prefix, and is not absolute (does
// not begin with '/') then the path traversed is relative to the [src].parent
func (f *FileSystem) targetByPathWithRoot(path string, src Resource) (name string, parent Resource, err error) {
	id, path, err := parseUUIDPrefix(path)
	if err != nil {
		return "", Resource{}, err
	}
	if id.Valid {
		f = f.withPathRoot(id)
	} else if len(path) == 0 {
		return "", Resource{}, ErrResourceNameInvalid
	} else if path[0] != '/' && src.id != uuid.Nil {
		f = f.withPathRoot(pgtype.UUID{Bytes: src.parentID.Bytes, Valid: true})
	}

	path = strings.TrimRight(path, "/")
	i := strings.LastIndex(path, "/")
	parentPath := ""
	if i > 0 {
		parentPath = path[:i]
	}
	parent, err = f.ResourceByPath(parentPath)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}

		return "", Resource{}, err
	}
	name = path[i+1:]
	if name == "" {
		name = src.name
	}
	return name, parent, nil
}

// detectNameConflict checks if there already exists a [Resource] with parent
// [parentID] and name [name]. If there isn't then it simply returns [name]
//
// If there is a conflict and [autoRename] is `false`, then it returns
// [ErrResourceNameConflict], along with the name passed in.
//
// If there is a conflict and [autoRename] is `true` then it returns a name with
// the first available numbered suffix.
func detectNameConflict(db db.Handler, parentID uuid.UUID, name string, autoRename bool) (string, error) {
	if _, _, err := childResourceIDByName(db, parentID, name); err != nil {
		// No name conflict. Good to go!
		if errors.Is(err, ErrResourceNotFound) {
			return name, nil
		}
		return "", err
	} else if !autoRename {
		return name, ErrResourceNameConflict
	}

	ext := path.Ext(name)
	basename := name[:len(name)-len(ext)]
	counter := 1
	for {
		name = fmt.Sprintf("%s (%d)%s", basename, counter, ext)
		if _, _, err := childResourceIDByName(db, parentID, name); err == nil {
			counter++
		} else if errors.Is(err, ErrResourceNotFound) {
			return name, nil
		} else {
			return "", err
		}
	}
}

func childResourceIDByName(db db.Handler, parentID uuid.UUID, name string) (uuid.UUID, bool, error) {
	const query = "SELECT id, dir FROM resources WHERE parent = @parent::UUID AND name = @name::TEXT AND deleted IS NULL"
	args := pgx.NamedArgs{
		"parent": parentID,
		"name":   name,
	}
	row := db.QueryRow(query, args)
	var id uuid.UUID
	var dir bool
	err := row.Scan(&id, &dir)
	if Is(err, pgx.ErrNoRows) {
		err = ErrResourceNotFound
	}
	return id, dir, err
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
