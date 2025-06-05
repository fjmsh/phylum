package core

import (
	"errors"
	"fmt"
	"path"
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

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
	if CheckNameInvalid(name) {
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
			res, err = f.childResourceByName(parent, name)
			if err == nil && res.dir != dir {
				err = ErrResourceNameConflict
			}
		case ResourceBindConflictResolutionRename:
			ext := path.Ext(name)
			basename := name[:len(name)-len(ext)]
			counter := 1
			for {
				name := fmt.Sprintf("%s (%d)%s", basename, counter, ext)
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
				if err != nil {
					if !strings.Contains(err.Error(), "unique_member_resource_name") {
						return
					}
					counter++
				} else {
					created = true
					return
				}
			}
		case ResourceBindConflictResolutionOverwrite:
			res, err = f.childResourceByName(parent, name)
			if err == nil {
				deleted = true
				if res.dir == dir {
					if dir {
						err = f.deleteRecursive(res.id, parent, true, true)
					}
				} else {
					err = f.deleteRecursive(res.id, parent, true, false)
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
			res, err = f.childResourceByName(parent, name)
			if err == nil {
				deleted = true
				err = f.deleteRecursive(res.id, parent, true, false)
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
