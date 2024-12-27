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
	err := r.f.db.WithTx(r.f.ctx, func(d *db.DbHandler) error {
		var err error
		parent := r.ID()
		f := r.f.withDb(d)
		if result, created, err = f.createResourceInDB(id, &parent, name, dir, conflictResolution); err != nil {
			return err
		} else if created {
			return d.UpdateResourceModified(r.f.ctx, parent)
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

	info := ResourceInfoFromDBResource(result)
	if r.Path() == "/" {
		info.path = "/" + info.name
	} else {
		info.path = r.Path() + "/" + info.name
	}
	ancestry := make([]ResourceInfo, len(r.Ancestors)+1)
	copy(ancestry, r.Ancestors)
	ancestry = append(ancestry, r.Info)
	return Resource{
		f:              r.f,
		Ancestors:      ancestry,
		Info:           info,
		userPermission: r.userPermission,
	}, nil
}

func (f filesystem) createResourceInDB(id uuid.UUID, parent *uuid.UUID, name string, dir bool, conflictResolution ResourceBindConflictResolution) (db.Resource, bool, error) {
	if created, err := f.db.CreateResource(f.ctx, db.CreateResourceParams{ID: id, Parent: parent, Name: name, Dir: dir}); err != nil {
		if strings.Contains(err.Error(), "unique_member_resource_name") {
			switch conflictResolution {
			case ResourceBindConflictResolutionError:
				return db.Resource{}, false, ErrResourceNameConflict
			case ResourceBindConflictResolutionEnsure:
				existing, err := f.db.ChildResourceByName(f.ctx, db.ChildResourceByNameParams{Parent: *parent, Name: "name"})
				if err == nil && existing.Dir != dir {
					err = ErrResourceNameConflict
				}
				if err != nil {
					return db.Resource{}, false, err
				}
				return existing, false, nil
			case ResourceBindConflictResolutionRename:
				ext := path.Ext(name)
				basename := name[:len(name)-len(ext)]
				counter := 1
				for {
					name := fmt.Sprintf("%s (%d).%s", basename, counter, ext)
					if ext == "" {
						name = fmt.Sprintf("%s (%d)", basename, counter)
						if created, err := f.db.CreateResource(f.ctx, db.CreateResourceParams{ID: id, Parent: parent, Name: name, Dir: dir}); err != nil {
							if !strings.Contains(err.Error(), "unique_member_resource_name") {
								return db.Resource{}, false, err
							}
							counter++
						} else {
							return created, true, nil
						}
					}
				}
			case ResourceBindConflictResolutionOverwrite:
				existing, err := f.db.ChildResourceByName(f.ctx, db.ChildResourceByNameParams{Parent: *parent, Name: "name"})
				if err != nil {
					return db.Resource{}, false, err
				}
				if existing.Dir == dir {
					if dir {
						f.deleteRecursive(id, *parent, true, true)
					}
					return existing, false, nil
				}
				err = f.deleteRecursive(id, *parent, true, false)
				if err != nil {
					return db.Resource{}, false, err
				}
				return f.createResourceInDB(id, parent, name, dir, ResourceBindConflictResolutionError)
			case ResourceBindConflictResolutionDelete:
				err := f.deleteRecursive(id, *parent, true, false)
				if err != nil {
					return db.Resource{}, false, err
				}
				return f.createResourceInDB(id, parent, name, dir, ResourceBindConflictResolutionError)
			}
		}
		if strings.Contains(err.Error(), "resources_pkey") {
			// TODO: maybe the request already succeeded in the previous attempt but the client didn't receive the response?
			err = ErrResourceIDConflict
		}
		return db.Resource{}, false, err
	} else {
		return created, true, nil
	}
}

func ResourceInfoFromDBResource(r db.Resource) ResourceInfo {
	var delTime *time.Time
	if r.Deleted.Valid {
		delTime = &r.Deleted.Time
	}
	return ResourceInfo{
		id:            r.ID,
		parentID:      r.Parent,
		name:          r.Name,
		dir:           r.Dir,
		created:       r.Created.Time,
		modified:      r.Modified.Time,
		deleted:       delTime,
		contentSize:   r.ContentSize,
		contentType:   r.ContentType,
		contentSHA256: r.ContentSha256,
	}
}
