package fs

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func (r Resource) Move(target string, overwrite bool) (Resource, bool, error) {
	if r.ParentID == nil {
		return Resource{}, false, ErrInsufficientPermissions
	}

	// Check source directory permissions
	parent, err := r.f.ResourceByID(*r.ParentID)
	if err != nil {
		return Resource{}, false, err
	}
	if !parent.hasPermission(PermissionRead | PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}

	// Check destParent directory permissions (if applicable)
	destParent, destName, err := r.f.targetByPathOrUUID(r, target)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, false, err
	}
	if !destParent.hasPermission(PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}
	if res, err := r.f.db.ResourceByID(r.f.ctx, db.ResourceByIDParams{Root: r.ID, ResourceID: destParent.ID, Username: r.f.username}); err != nil || res.Found {
		return Resource{}, false, ErrResourceMoveTargetSubdirectory
	}

	var deleted = false
	return r, deleted, r.f.db.WithTx(r.f.ctx, func(dbh *db.DbHandler) error {
		f := r.f.withDb(dbh)
		if overwrite {
			if err := destParent.DeleteChildRecursive(destName, false); err == nil {
				deleted = true
			} else if !errors.Is(err, ErrResourceNotFound) {
				return err
			}
		}
		if nameParent, err := f.db.UpdateResourceNameParent(f.ctx, db.UpdateResourceNameParentParams{ID: r.ID, Name: destName, Parent: destParent.ID}); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			return err
		} else {
			r.Name = nameParent.Name
			r.ParentID = nameParent.Parent
			return nil
		}
	})
}

func (r Resource) Copy(target string, id uuid.UUID, recursive, overwrite bool) (Resource, bool, error) {
	// Check source directory permissions
	if !r.hasPermission(PermissionRead) {
		return Resource{}, false, ErrInsufficientPermissions
	}

	// Check dest directory permissions
	destParent, destName, err := r.f.targetByPathOrUUID(r, target)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, false, err
	}
	if !destParent.Dir {
		return Resource{}, false, ErrResourceNotCollection

	}
	if !destParent.hasPermission(PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}

	var tree []db.ReadDirRow
	if recursive && r.Dir {
		var err error
		tree, err = r.f.db.ReadDir(r.f.ctx, db.ReadDirParams{ID: r.ID, IncludeRoot: false, Recursive: true})
		if err != nil {
			return Resource{}, false, err
		}
	}
	create := make([]db.CreateResourcesParams, 0, len(tree)+1)
	copy := make(map[uuid.UUID]uuid.UUID)
	ids := make(map[string]uuid.UUID)
	if r.Dir {
		ids[""] = id
	} else {
		copy[r.ID] = id
	}

	create = append(create, db.CreateResourcesParams{
		ID:            id,
		Parent:        destParent.ID,
		Name:          destName,
		Dir:           r.Dir,
		ContentSize:   r.ContentSize,
		ContentType:   r.ContentType,
		ContentSha256: r.ContentSHA256,
	})
	for _, src := range tree {
		id, _ := uuid.NewUUID()
		parent := ids[src.Path[0:strings.LastIndex(src.Path, "/")]]

		create = append(create, db.CreateResourcesParams{
			ID:            id,
			Parent:        parent,
			Name:          src.Name,
			Dir:           src.Dir,
			ContentSize:   src.ContentSize,
			ContentType:   src.ContentType,
			ContentSha256: src.ContentSha256,
		})

		if src.Dir {
			ids[src.Path] = id
		} else {
			copy[src.ID] = id
		}
	}

	var deleted = false
	err = r.f.db.WithTx(r.f.ctx, func(dbh *db.DbHandler) error {
		f := r.f.withDb(dbh)
		if overwrite {
			if err := destParent.DeleteChildRecursive(destName, false); err == nil {
				deleted = true
			} else if !errors.Is(err, ErrResourceNotFound) {
				return err
			}
		}
		if _, err := dbh.CreateResources(f.ctx, create); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			return err
		}
		return dbh.UpdateResourceModified(f.ctx, destParent.ID)
	})

	if err == nil {
		func() {
			for k, v := range copy {
				if err := r.f.cs.CopyContents(k, v); err != nil {
					logrus.Warn("unable to copy " + k.String() + " to " + v.String() + ": " + err.Error())
				}
			}

		}()
	}

	var dest = Resource{
		f:             r.f,
		ID:            id,
		ParentID:      &destParent.ID,
		Name:          destName,
		Dir:           r.Dir,
		Created:       time.Now(),
		Modified:      time.Now(),
		Deleted:       nil,
		ContentSize:   r.ContentSize,
		ContentType:   r.ContentType,
		ContentSHA256: r.ContentSHA256,
		Permissions:   "{}",
		// Not Needed
		// UserPermissions:      ??
		// InheritedPermissions: ??
		// Path:                 destParent.Path + "/" + destName,
	}
	return dest, deleted, err
}

// targetByPathOrUUID splits a target path or uuid into its constituent components
// `pathOrUUID` can be of the following formats:
// 1. absolute path beginning with '/'
// 2. uuid+name separated by ':'
// For the latter, if either uuid or name is not provided then it is filled in from `src`
func (f filesystem) targetByPathOrUUID(src Resource, pathOrUUID string) (Resource, string, error) {
	index := strings.Index(pathOrUUID, ":")
	if index == -1 {
		if pathOrUUID[0] != '/' {
			return Resource{}, "", ErrResourcePathInvalid
		}
		path := strings.TrimRight(pathOrUUID, "/")
		// if dest, err := f.ResourceByPath(path); err == nil {
		// 	return dest, src.Name, nil
		// } else {
		index := strings.LastIndex(path, "/")
		name := path[index+1:]
		path = path[0:index]
		if parent, err := f.ResourceByPath(path); err != nil {
			if errors.Is(err, ErrResourceNotFound) {
				err = ErrParentNotFound
			}
			return Resource{}, "", err
		} else if CheckNameInvalid(name) {
			return Resource{}, "", ErrResourceNameInvalid
		} else {
			return parent, name, nil
		}
		// }
	}
	var parent Resource
	if index == 0 {
		parent = src
	} else {
		if id, err := uuid.Parse(pathOrUUID[0:index]); err != nil {
			return Resource{}, "", err
		} else if res, err := f.ResourceByID(id); err != nil {
			if errors.Is(err, ErrResourceNotFound) {
				err = ErrParentNotFound
			}
			return Resource{}, "", err
		} else {
			parent = res
		}

	}

	name := pathOrUUID[index+1:]
	if name == "" {
		name = src.Name
	} else if CheckNameInvalid(name) {
		return Resource{}, "", ErrResourceNameInvalid
	}

	return parent, name, nil
}
