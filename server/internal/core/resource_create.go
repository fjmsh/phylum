package core

import (
	"errors"
	"fmt"
	"path"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type ResourceBindConflictResolution int32

const (
	ResourceBindConflictResolutionError     = ResourceBindConflictResolution(0) // Error if exists
	ResourceBindConflictResolutionEnsure    = ResourceBindConflictResolution(1) // Error if type mismatch
	ResourceBindConflictResolutionRename    = ResourceBindConflictResolution(2) // Auto rename new resource
	ResourceBindConflictResolutionOverwrite = ResourceBindConflictResolution(3) // Delete existing resource only if type mismatch (preserves props)
	ResourceBindConflictResolutionDelete    = ResourceBindConflictResolution(4) // Delete existing resource before creating
)

func CheckResourceNameInvalid(s string) bool {
	return s == "" || s == "." || s == ".." || strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}

func (f filesystem) CreateResourceByPath(path string, id uuid.UUID, dir, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if id == uuid.Nil {
		id, _ = uuid.NewV7()
	}

	if !createParents {
		name, parent, err := f.targetNameParentByPathWithRoot(path, Resource{})
		if err != nil {
			if errors.Is(err, ErrResourceNotFound) {
				err = ErrParentNotFound
			}
			return Resource{}, err
		}
		return f.createMemberResource(parent, name, id, dir, conflictResolution)
	}

	root, path, err := parseUUIDPrefix(path)
	if err != nil {
		return Resource{}, ErrResourcePathInvalid
	}
	if root.Valid {
		f = f.withPathRoot(root)
	}
	segments := strings.Split(strings.TrimRight(strings.TrimLeft(path, "/"), "/"), "/")
	r, err := f.ResourceByID(f.pathRoot.Bytes)
	for i, s := range segments {
		if err != nil {
			return Resource{}, err
		}
		d := true
		resourceID, _ := uuid.NewV7()
		conflict := ResourceBindConflictResolutionEnsure
		if i == len(segments)-1 {
			d = dir
			resourceID = id
			conflict = conflictResolution
		}
		r, err = f.createMemberResource(r, s, resourceID, d, conflict)
	}

	return r, err
}

// For bulk insert
type CreateResourcesParams struct {
	ID     uuid.UUID
	Parent uuid.UUID
	Name   string
	Dir    bool
}

// TODO: Make not public
func (f filesystem) CreateResources(arg []CreateResourcesParams) (int64, error) {
	return f.db.CopyFrom([]string{"resources"}, []string{"id", "parent", "name", "dir"}, &iteratorForCreateResources{rows: arg})
}

func (f filesystem) createMemberResource(r Resource, name string, id uuid.UUID, dir bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if r.deleted.Valid {
		return Resource{}, ErrResourceDeleted
	}
	if !r.Dir() {
		return Resource{}, ErrResourceNotCollection
	}
	if !r.hasPermission(PermissionWrite) {
		return Resource{}, ErrInsufficientPermissions
	}
	if CheckResourceNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}
	if id == uuid.Nil {
		id, _ = uuid.NewV7()
	}
	var res Resource
	var created bool
	err := f.runInTx(func(f filesystem) error {
		var err error
		if res, created, _, err = f.createResource(id, r.id, name, dir, r.permissions, conflictResolution); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			return err
		} else if created {
			if err := f.recomputePermissions(id); err != nil {
				return err
			}
			return f.updateResourceModified(r.id)
		}
		return nil
	})
	if err == ErrResourceIDConflict {
		return f.ResourceByID(id)
	}
	if err != nil {
		return Resource{}, err
	}

	res.userPermission = r.userPermission
	return res, nil
}

func (f filesystem) createResource(
	id uuid.UUID,
	parent uuid.UUID,
	name string,
	dir bool,
	permissions []byte,
	conflictResolution ResourceBindConflictResolution,
) (res Resource, created, deleted bool, err error) {
	err = f.runInTx(func(f filesystem) error {
		res, err = f.insertResource(
			id,
			parent,
			name,
			dir,
			permissions,
		)
		return err
	})
	if err == nil {
		created = true
		return
	}
	if strings.Contains(err.Error(), "unique_member_resource_name") {
		switch conflictResolution {
		case ResourceBindConflictResolutionError:
			err = ErrResourceNameConflict
		case ResourceBindConflictResolutionEnsure:
			var rDir bool
			_, rDir, err = f.childResourceIDByName(parent, name)
			if err == nil && rDir != dir {
				err = ErrResourceNameConflict
			}
		case ResourceBindConflictResolutionRename:
			if name, err = f.detectNameConflict(parent, name, true); err != nil {
				return
			} else {
				res, err = f.insertResource(
					id,
					parent,
					name,
					dir,
					permissions,
				)
				return
			}
		case ResourceBindConflictResolutionOverwrite:
			var rID uuid.UUID
			var rDir bool
			rID, rDir, err = f.childResourceIDByName(parent, name)
			if err == nil {
				deleted = true
				if rDir == dir {
					if dir {
						err = f.softDeleteChildren(rID, parent)
					}
					if err == nil {
						// Repurpose existing resource
						res, err = f.ResourceByID(rID)
					}
				} else {
					err = softDelete(f.db, res.id)
					if err == nil {
						res, created, _, err = f.createResource(
							id,
							parent,
							name,
							dir,
							permissions,
							ResourceBindConflictResolutionError,
						)
					}
				}
			}
		case ResourceBindConflictResolutionDelete:
			var rID uuid.UUID
			rID, _, err = f.childResourceIDByName(parent, name)
			if err == nil {
				deleted = true
				err = softDelete(f.db, rID)
				if err == nil {
					res, created, _, err = f.createResource(
						id,
						parent,
						name,
						dir,
						permissions,
						ResourceBindConflictResolutionError,
					)
				}
			}
		}
	} else if strings.Contains(err.Error(), "resources_pkey") {
		// TODO: maybe the request already succeeded in the previous attempt but the client didn't receive the response?
		err = ErrResourceIDConflict
	}
	return
}

func (f filesystem) insertResource(id, parent uuid.UUID, name string, dir bool, permissions []byte) (Resource, error) {
	query, args, _ := pg.From("resources").
		Insert().
		Rows(goqu.Record{
			"id":          goqu.V(id),
			"parent":      goqu.V(parent),
			"name":        goqu.V(name),
			"dir":         goqu.V(dir),
			"permissions": goqu.V(permissions),
		}).
		Returning(
			"*",
			goqu.L("'[]'::JSONB"), // versions
			goqu.L("'[]'::JSONB"), // links
			goqu.L("NULL"),        // visible parent
			goqu.L("'{}'::JSONB"), // inherited permissions
		).
		ToSQL()
	if rows, err := f.db.Query(query, args...); err != nil {
		return Resource{}, err
	} else {
		r, err := f.collectFullResource(rows)
		r.parentID = pgtype.UUID{Bytes: parent, Valid: true}
		r.visibleParent = r.parentID
		r.inheritedPermissions = permissions
		return r, err
	}
}

func (f filesystem) updateResourceModified(id uuid.UUID) error {
	const q = "UPDATE resources SET modified = NOW() WHERE id = $1"
	_, err := f.db.Exec(q, id)
	return err
}

func (f filesystem) createResourceVersion(id, versionID uuid.UUID, size int64, mimeType, sha256 string) error {
	const q = `INSERT INTO resource_versions(id, resource_id, size, mime_type, sha256, storage)
	VALUES (@version_id::UUID, @resource_id::UUID, @size::INT, @mime_type::TEXT, @sha256::TEXT, @storage::TEXT)`

	args := pgx.NamedArgs{
		"resource_id": id,
		"version_id":  versionID,
		"size":        size,
		"mime_type":   mimeType,
		"sha256":      sha256,
		"storage":     storage.DefaultBackendName,
	}
	_, err := f.db.Exec(q, args)
	return err
}

func (f filesystem) detectNameConflict(parentID uuid.UUID, name string, autoRename bool) (string, error) {
	if _, _, err := f.childResourceIDByName(parentID, name); err != nil {
		// No name conflict. Good to go!
		if errors.Is(err, ErrResourceNotFound) {
			return name, nil
		}
		return "", err
	} else if !autoRename {
		return "", ErrResourceNameConflict
	}

	ext := path.Ext(name)
	basename := name[:len(name)-len(ext)]
	counter := 1
	for {
		name = fmt.Sprintf("%s (%d)%s", basename, counter, ext)
		if _, _, err := f.childResourceIDByName(parentID, name); err == nil {
			counter++
		} else if errors.Is(err, ErrResourceNotFound) {
			return name, nil
		} else {
			return "", err
		}
	}
}

// iteratorForCreateResources implements pgx.CopyFromSource.
type iteratorForCreateResources struct {
	rows                 []CreateResourcesParams
	skippedFirstNextCall bool
}

func (r *iteratorForCreateResources) Next() bool {
	if len(r.rows) == 0 {
		return false
	}
	if !r.skippedFirstNextCall {
		r.skippedFirstNextCall = true
		return true
	}
	r.rows = r.rows[1:]
	return len(r.rows) > 0
}

func (r iteratorForCreateResources) Values() ([]interface{}, error) {
	return []interface{}{
		r.rows[0].ID,
		r.rows[0].Parent,
		r.rows[0].Name,
		r.rows[0].Dir,
	}, nil
}

func (r iteratorForCreateResources) Err() error {
	return nil
}
