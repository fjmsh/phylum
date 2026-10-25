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
	if r, err := f.resourceByID(id); err != nil {
		return Resource{}, err
	} else if err := r.checkPermission(ResourcePermissionRead); err != nil {
		if errors.Is(err, ErrInsufficientPermissions) || errors.Is(err, ErrInsufficientScope) {
			err = ErrResourceNotFound
		}
		return Resource{}, err
	} else {
		return r, nil
	}
}

func (f *FileSystem) resourceByID(id uuid.UUID) (Resource, error) {
	query := fullResourceQuery + "\nWHERE r.id = @id::UUID"
	args := pgx.NamedArgs{
		"id": id,
	}
	if rows, err := f.db.Query(query, args); err != nil {
		return Resource{}, err
	} else {
		return f.collectFullResource(rows)
	}
}

// // ResourceByPath locates the resource at [path]. [path] may begin with
// // a "<uuid>:" prefix, which will traverse the path relative to that root
// // instead of this [FileSystem]'s default [PathRoot].
// //
// // An empty path or "/" will return the root resource.
// //
// // A permission check will be performed to ensure that the [FileSystem]'s [User]
// // has read permissions on the resource. If not, then [ErrResourceNotFound] will
// // be returned.
// func (f *FileSystem) ResourceByPath(path string) (Resource, error) {
// 	return f.ResourceByPath(path)
// }

// ResourceByPath locates the resource at [path].
//
// An empty path or "/" will return the root resource.
//
// A permission check will be performed to ensure that the [FileSystem]'s [User]
// has read permissions on the resource. If not, then [ErrResourceNotFound] will
// be returned.
func (f *FileSystem) ResourceByPath(path string) (Resource, error) {
	f, path, err := f.parsePathRoot(path)
	if err != nil {
		return Resource{}, err
	}

	if !f.pathRoot.Valid {
		return Resource{}, ErrResourceNotFound
	}
	if path == "" {
		if res, err := f.ResourceByID(f.pathRoot.Bytes); err != nil {
			return res, err
		}
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
	a := goqu.T("resource_ancestors").As("a")
	q := pg.Select(r.All(),
		goqu.L("COALESCE(?, '[]'::JSONB)", v.Col("versions")),
		goqu.L("COALESCE(?, '[]'::JSONB)", l.Col("publinks")),
		pg.Select(goqu.L("COALESCE(p.permissions, '{}'::JSONB)")),
		a.Col("ancestors"),
	).
		From(r).
		LeftJoin(goqu.T("resources").As("p"), goqu.On(p.Col("id").Eq(r.Col("parent")))).
		WithRecursive("nodes(id, parent, search, depth)", rec).
		Join(nodes, goqu.On(r.Col("id").Eq(nodes.Col("id")))).
		LeftJoin(v, goqu.On(r.Col("id").Eq(v.Col("id")))).
		LeftJoin(l, goqu.On(r.Col("id").Eq(l.Col("id")))).
		LeftJoin(a, goqu.On(r.Col("id").Eq(a.Col("id")))).
		Where(goqu.L("cardinality(n.search) = n.depth"))

	query, args, _ := q.ToSQL()

	if rows, err := f.db.Query(query, args...); err != nil {
		return Resource{}, err
	} else if r, err := f.collectFullResource(rows); err != nil {
		return Resource{}, err
	} else if err := r.checkPermission(ResourcePermissionRead); err != nil {
		if errors.Is(err, ErrInsufficientPermissions) || errors.Is(err, ErrInsufficientScope) {
			err = ErrResourceNotFound
		}
		return Resource{}, err
	} else {
		return r, nil
	}
}

// targetByPathWithRoot extracts the [name] and [parent] directory from
// the given [path].
//
// If there is a file present at the
// Uses the last segment of [path] as the [name] and traverses the previous
// segments to locate [parent]. If [path] has no segments then [src].[name]
// is used as the [name] instead.
func (f *FileSystem) targetByPathWithRoot(path string, allowEmptyName bool) (parent Resource, name string, err error) {
	f, path, err = f.parsePathRoot(path)
	if err != nil {
		return
	}

	path = strings.TrimRight(path, "/")
	if allowEmptyName {
		parent, err = f.ResourceByPath(path)
	}
	if parent.id != uuid.Nil {
		if !parent.dir {
			// The found resource isn't a directory. Use the parent instead
			if parent.id == f.pathRoot.Bytes {
				// Parent is already the path root. Cannot go higher
				return Resource{}, "", ErrParentNotFound
			}
			name = parent.name
			parent, err = f.resourceByID(parent.id)
		}
	} else if err != nil && !errors.Is(err, ErrResourceNotFound) {
		// err will be nil if allowEmptyName is true
		return
	} else {
		i := strings.LastIndex(path, "/")
		if i > 0 {
			name = path[i+1:]
			path = path[:i]

			parent, err = f.ResourceByPath(path)
			if err != nil {
				if errors.Is(err, ErrResourceNotFound) {
					err = ErrParentNotFound
				}
				return
			}
		} else {
			err = ErrParentNotFound
			return
		}
	}

	if parent.deleted.Valid {
		return Resource{}, "", ErrParentNotFound
	}
	if err = parent.checkPermission(ResourcePermissionWrite); err != nil {
		return Resource{}, "", err
	}
	return
}

// parsePathRoot incorporates the path root if one is present in the path, and returns
// the remaining path
//
// The following path roots are recognized:
// - '/' for an absolute path
// - '~' for a path relative to the current user's home directory
// - '~<user>' for a path relative to another user's home directory
// - ':<uuid>' for a path relative to a resource with id <uuid>
func (f *FileSystem) parsePathRoot(path string) (*FileSystem, string, error) {
	if len(path) == 0 {
		if !f.pathRoot.Valid {
			return nil, path, ErrResourcePathInvalid
		}
		return f, path, nil
	}
	if path[0] == ':' {
		i := strings.Index(path, "/")
		var idStr string
		if i < 0 {
			idStr = path[1:]
			path = ""
		} else {
			idStr = path[1:i]
			path = path[i+1:]
		}
		if id, err := uuid.Parse(idStr); err != nil {
			return nil, path, ErrResourcePathInvalid
		} else {
			return f.WithPathRoot(pgtype.UUID{Bytes: id, Valid: true}), path, nil
		}
	}
	if path[0] == '~' {
		i := strings.Index(path, "/")
		var user string
		if i < 0 {
			user = path[1:]
			path = ""
		} else {
			user = path[1:i]
			path = path[i+1:]
		}
		if user == "" {
			if !f.home.Valid {
				return nil, path, ErrResourceNotFound
			}
		}
		if userHome, err := UserHome(f.db, user); err != nil {
			if errors.Is(err, ErrUserNotFound) {
				err = ErrResourceNotFound
			}
			return nil, path, err
		} else if !userHome.Valid {
			return nil, path, ErrResourceNotFound
		} else {
			return f.WithPathRoot(userHome), path, nil
		}
	}
	if path[0] == '/' {
		return f.WithPathRoot(fsPathRoot), path[1:], nil
	}
	if !f.pathRoot.Valid {
		return nil, path, ErrResourcePathInvalid
	}
	return f, path, nil
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
