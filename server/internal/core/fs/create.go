package fs

import (
	"errors"
	"fmt"
	"path"
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
)

const emptyContentType = "text/plain"
const emptyContentSHA256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

func (f filesystem) CreateResourceByPath(path string, id uuid.UUID, dir, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if !createParents {
		name, parent, err := f.targetNameParentByPathWithRoot(path, Resource{})
		if err != nil {
			if errors.Is(err, ErrResourceNotFound) {
				err = ErrParentNotFound
			}
			return Resource{}, err
		}
		return parent.createMemberResource(name, id, dir, conflictResolution)
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
			if id != uuid.Nil {
				resourceID = id
			}
			conflict = conflictResolution
		}
		r, err = r.createMemberResource(s, resourceID, d, conflict)
	}

	return r, err
}

func (r Resource) createMemberResource(name string, id uuid.UUID, dir bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
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
	err := r.f.runInTx(func(f filesystem) error {
		var err error
		if res, created, _, err = f.createResource(id, r.id, name, dir, 0, emptyContentType, emptyContentSHA256, r.permissions, conflictResolution); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			return err
		} else if created {
			if err := f.recomputePermissions(r.id); err != nil {
				return err
			}
			return f.updateResourceModified(r.id)
		}
		return nil
	})
	if err == ErrResourceIDConflict {
		return r.f.ResourceByID(id)
	}
	if err != nil {
		return Resource{}, err
	}
	if !r.Dir() {
		out, err := r.f.cs.OpenWrite(id, nil, nil)
		if err == nil {
			err = out.Close()
		}
		if err != nil {
			return Resource{}, err
		}
	}

	res.f = r.f
	res.userPermission = r.userPermission
	return res, nil
}

func (f filesystem) createResource(
	id uuid.UUID,
	parent uuid.UUID,
	name string,
	dir bool,
	contentLength int,
	contentType string,
	contentSHA256 string,
	permissions []byte,
	conflictResolution ResourceBindConflictResolution,
) (res Resource, created, deleted bool, err error) {
	err = f.runInTx(func(f filesystem) error {
		res, err = f.insertResource(
			id,
			parent,
			name,
			dir,
			contentLength,
			contentType,
			contentSHA256,
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
						contentLength,
						contentType,
						contentSHA256,
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
					} else {
						err = f.updateResourceContents(
							res.id,
							contentLength,
							contentType,
							contentSHA256,
						)
						res.contentLength = contentLength
						res.contentType = contentType
						res.contentSHA256 = contentSHA256
					}
				} else {
					err = f.deleteRecursive(res.id, parent, true, false)
					if err == nil {
						res, created, _, err = f.createResource(
							id,
							parent,
							name,
							dir,
							contentLength,
							contentType,
							contentSHA256,
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
						contentLength,
						contentType,
						contentSHA256,
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

func (f filesystem) insertResource(id, parent uuid.UUID, name string, dir bool, contentLength int, contentType, contentSha256 string, permissions []byte) (Resource, error) {
	query, args, _ := pg.From("resources").
		Insert().
		Rows(goqu.Record{
			"id":             goqu.V(id),
			"parent":         goqu.V(parent),
			"name":           goqu.V(name),
			"dir":            goqu.V(dir),
			"content_length": goqu.V(contentLength),
			"content_type":   goqu.V(contentType),
			"content_sha256": goqu.V(contentSha256),
			"permissions":    goqu.V(permissions),
		}).
		Returning("*").
		ToSQL()
	if rows, err := f.db.Query(query, args...); err != nil {
		return Resource{}, err
	} else {
		r, err := f.collectResource(rows, false)
		r.inheritedPermissions = permissions
		r.links = []byte{'[', ']'}
		return r, err
	}
}
