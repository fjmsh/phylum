package fs

import (
	"errors"
	"fmt"
	"path"
	"strings"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
)

const emptyContentType = "text/plain"
const emptyContentSHA256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

func (f filesystem) CreateResourceByPath(path string, dir, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	path = strings.TrimRight(path, "/")
	index := strings.LastIndex(path, "/")
	name := path[index+1:]
	parentPath := path[0:index]
	parent, err := f.ResourceByPath(parentPath)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			if recursive {
				// TODO: this is very inefficient, but used only directly from the command line
				parent, err = f.CreateResourceByPath(parentPath, true, true, conflictResolution)
			} else {
				err = ErrParentNotFound
			}
		}
		if err != nil {
			return Resource{}, err
		}
	}
	return parent.CreateMemberResource(name, uuid.Nil, dir, conflictResolution)
}

func (r Resource) CreateMemberResource(name string, id uuid.UUID, dir bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if !r.Dir() {
		return Resource{}, ErrResourceNotCollection
	}
	if !r.hasPermission(PermissionWrite) {
		return Resource{}, ErrInsufficientPermissions
	}
	if name == "" || CheckNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}
	if id == uuid.Nil {
		id, _ = uuid.NewV7()
	}
	var res Resource
	var created bool
	err := r.f.runInTx(func(f filesystem) error {
		var err error
		if res, created, _, err = f.createResource(id, r.id, name, dir, 0, emptyContentType, emptyContentSHA256, conflictResolution, r.permissions); err != nil {
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
	conflictResolution ResourceBindConflictResolution,
	permissions []byte,
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
			res, err = f.ChildResourceByName(parent, name)
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
			res, err = f.ChildResourceByName(parent, name)
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
							ResourceBindConflictResolutionError,
							permissions,
						)
					}
				}
			}
		case ResourceBindConflictResolutionDelete:
			res, err = f.ChildResourceByName(parent, name)
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
						ResourceBindConflictResolutionError,
						permissions,
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
	if rows, err := f.db.Query(f.ctx, query, args...); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows)
	}
}

func ResourceFromDB(r db.Resource) Resource {
	var delTime *time.Time
	if r.Deleted.Valid {
		delTime = &r.Deleted.Time
	}
	return Resource{
		id:            r.ID,
		parentID:      r.Parent,
		name:          r.Name,
		dir:           r.Dir,
		created:       r.Created.Time,
		modified:      r.Modified.Time,
		deleted:       delTime,
		contentLength: r.ContentLength,
		contentType:   r.ContentType,
		contentSHA256: r.ContentSha256,
		permissions:   r.Permissions,
		grants:        r.Grants,
	}
}
