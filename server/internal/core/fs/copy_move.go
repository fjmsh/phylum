package fs

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func (f filesystem) Move(r Resource, target string, overwrite bool) (Resource, bool, error) {
	if r.ParentID == nil {
		return Resource{}, false, ErrInsufficientPermissions
	}

	// Check source directory permissions
	parent, err := f.ResourceByID(*r.ParentID)
	if err != nil {
		return Resource{}, false, err
	}
	if !parent.hasPermission(PermissionRead | PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}

	// Check destParent directory permissions (if applicable)
	destParent, destName, err := f.targetByPathOrUUID(r, target)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, false, err
	}
	if !destParent.hasPermission(PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}
	if res, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: r.ID, ResourceID: destParent.ID, Username: f.username}); err != nil || res.Found {
		return Resource{}, false, ErrResourceMoveTargetSubdirectory
	}

	var result Resource
	var deleted = false
	return result, deleted, f.db.WithTx(f.ctx, func(dbh *db.DbHandler) error {
		f = f.withDb(dbh)
		if overwrite {
			if err := f.DeleteChildRecursive(destParent, destName, false); err == nil {
				deleted = true
			} else if !errors.Is(err, ErrResourceNotFound) {
				return err
			}
		}
		if r, err := f.db.UpdateResourceNameParent(f.ctx, db.UpdateResourceNameParentParams{ID: r.ID, Name: destName, Parent: destParent.ID}); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			return err
		} else {
			result = ResourceFromDB(r, 0, "", "")
			return nil
		}
	})
}

func (f filesystem) Copy(src Resource, target string, id uuid.UUID, recursive, overwrite bool) (Resource, bool, error) {
	// Check source directory permissions
	if !src.hasPermission(PermissionRead) {
		return Resource{}, false, ErrInsufficientPermissions
	}

	// Check dest directory permissions
	destParent, destName, err := f.targetByPathOrUUID(src, target)
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
	if recursive && src.Dir {
		var err error
		tree, err = f.db.ReadDir(f.ctx, db.ReadDirParams{ID: src.ID, IncludeRoot: false, Recursive: true})
		if err != nil {
			return Resource{}, false, err
		}
	}
	create := make([]db.CreateResourcesParams, 0, len(tree)+1)
	copy := make(map[uuid.UUID]uuid.UUID)
	ids := make(map[string]uuid.UUID)
	if src.Dir {
		ids[""] = id
	} else {
		copy[src.ID] = id
	}

	create = append(create, db.CreateResourcesParams{
		ID:            id,
		Parent:        destParent.ID,
		Name:          destName,
		Dir:           src.Dir,
		ContentSize:   src.ContentSize,
		ContentType:   src.ContentType,
		ContentSha256: src.ContentSHA256,
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
	err = f.db.WithTx(f.ctx, func(dbh *db.DbHandler) error {
		f := f.withDb(dbh)
		if overwrite {
			if err := f.DeleteChildRecursive(destParent, destName, false); err == nil {
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
				if err := f.cs.CopyContents(k, v); err != nil {
					logrus.Warn("unable to copy " + k.String() + " to " + v.String() + ": " + err.Error())
				}
			}

		}()
	}

	var dest = Resource{
		ID:            id,
		ParentID:      &destParent.ID,
		Name:          destName,
		Dir:           src.Dir,
		Created:       time.Now(),
		Modified:      time.Now(),
		Deleted:       nil,
		ContentSize:   src.ContentSize,
		ContentType:   src.ContentType,
		ContentSHA256: src.ContentSHA256,
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
