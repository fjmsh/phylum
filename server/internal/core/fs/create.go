package fs

import (
	"errors"
	"fmt"
	"path"
	"strings"
	"time"

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
	var result db.Resource
	var created bool
	err := r.f.runInTx(func(f filesystem) error {
		var err error
		parent := r.ID()
		if result, created, _, err = f.createResource(id, parent, name, dir, 0, emptyContentType, emptyContentSHA256, conflictResolution); err != nil {
			return err
		} else if created {
			if err := f.db.RecomputePermissions(f.ctx, id); err != nil {
				return err
			}
			return f.db.UpdateResourceModified(f.ctx, parent)
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

	res := ResourceFromDB(result)
	res.f = r.f
	res.userPermission = r.userPermission
	return res, nil
}

func (f filesystem) createResource(
	id uuid.UUID,
	parent uuid.UUID,
	name string,
	dir bool,
	contentLength int64,
	contentType string,
	contentSHA256 string,
	conflictResolution ResourceBindConflictResolution,
) (res db.Resource, created, deleted bool, err error) {
	err = f.runInTx(func(f filesystem) error {
		res, err = f.db.CreateResource(f.ctx, db.CreateResourceParams{
			ID:            id,
			Parent:        &parent,
			Name:          name,
			ContentLength: contentLength,
			ContentType:   contentType,
			ContentSha256: contentSHA256,
			Dir:           dir,
		})
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
			res, err = f.db.ChildResourceByName(f.ctx, db.ChildResourceByNameParams{Parent: parent, Name: name})
			if err == nil && res.Dir != dir {
				err = ErrResourceNameConflict
			}
		case ResourceBindConflictResolutionRename:
			ext := path.Ext(name)
			basename := name[:len(name)-len(ext)]
			counter := 1
			for {
				name := fmt.Sprintf("%s (%d)%s", basename, counter, ext)
				err = f.runInTx(func(f filesystem) error {
					res, err = f.db.CreateResource(f.ctx, db.CreateResourceParams{
						ID:            id,
						Parent:        &parent,
						Name:          name,
						ContentLength: contentLength,
						ContentType:   contentType,
						ContentSha256: contentSHA256,
						Dir:           dir,
					})
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
			res, err = f.db.ChildResourceByName(f.ctx, db.ChildResourceByNameParams{Parent: parent, Name: name})
			if err == nil {
				deleted = true
				if res.Dir == dir {
					if dir {
						err = f.deleteRecursive(res.ID, parent, true, true)
					} else {
						err = f.db.UpdateResourceContents(f.ctx, db.UpdateResourceContentsParams{
							ID:            res.ID,
							ContentLength: contentLength,
							ContentType:   contentType,
							ContentSha256: contentSHA256,
						})
						res.ContentLength = contentLength
						res.ContentType = contentType
						res.ContentSha256 = contentSHA256
					}
				} else {
					err = f.deleteRecursive(res.ID, parent, true, false)
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
						)
					}
				}
			}
		case ResourceBindConflictResolutionDelete:
			res, err = f.db.ChildResourceByName(f.ctx, db.ChildResourceByNameParams{Parent: parent, Name: name})
			if err == nil {
				deleted = true
				err = f.deleteRecursive(res.ID, parent, true, false)
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
