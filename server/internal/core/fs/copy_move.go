package fs

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

type ResourceBindConflictResolution int32

const (
	ResourceBindConflictResolutionNone      = 0
	ResourceBindConflictResolutionOverwrite = 1
	ResourceBindConflictResolutionRename    = 2
)

func (r Resource) Move(target string, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
	if r.ParentID() == nil {
		return Resource{}, false, ErrInsufficientPermissions
	}

	// Check source directory permissions
	parent, err := r.f.ResourceByID(*r.ParentID())
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
	if !destParent.Dir() {
		return Resource{}, false, ErrResourceNotCollection
	}
	if !destParent.hasPermission(PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}
	if res, err := r.f.db.ResourceByID(r.f.ctx, destParent.ID()); err != nil {
		return Resource{}, false, err
	} else {
		for i := 1; i < len(res); i++ {
			if res[i].ID == r.ID() {
				return Resource{}, false, ErrResourceMoveTargetSubdirectory
			}
		}
	}

	var deleted = false
	return r, deleted, r.f.db.WithTx(r.f.ctx, func(dbh *db.DbHandler) error {
		f := r.f.withDb(dbh)
		if conflictResolution == ResourceBindConflictResolutionOverwrite {
			if _, err := destParent.DeleteChildRecursive(destName, false); err == nil {
				deleted = true
			} else if !errors.Is(err, ErrResourceNotFound) {
				return err
			}
		}
		if nameParent, err := f.db.UpdateResourceNameParent(f.ctx, db.UpdateResourceNameParentParams{ID: r.ID(), Name: destName, Parent: destParent.ID()}); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			return err
		} else {
			r.Info.name = nameParent.Name
			r.Info.parentID = nameParent.Parent
			return nil
		}
	})
}

func (r Resource) Copy(target string, id uuid.UUID, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
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
	if !destParent.Dir() {
		return Resource{}, false, ErrResourceNotCollection

	}
	if !destParent.hasPermission(PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}

	var tree []db.FullResource
	if recursive && r.Dir() {
		var err error
		tree, err = r.f.db.ReadDir(r.f.ctx, db.ReadDirParams{ResourceID: r.ID(), MinDepth: 1, MaxDepth: 1000})
		if err != nil {
			return Resource{}, false, err
		}
	}
	create := make([]db.CreateResourcesParams, 0, len(tree)+1)
	contents := make(map[uuid.UUID]uuid.UUID)
	ids := make(map[uuid.UUID]uuid.UUID)
	if r.Dir() {
		ids[r.ID()] = id
	} else {
		contents[r.ID()] = id
	}

	create = append(create, db.CreateResourcesParams{
		ID:            id,
		Parent:        destParent.ID(),
		Name:          destName,
		Dir:           r.Dir(),
		ContentSize:   r.ContentSize(),
		ContentType:   r.ContentType(),
		ContentSha256: r.ContentSHA256(),
	})
	for _, src := range tree {
		id, _ := uuid.NewV7()
		parent := ids[*src.Parent]

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
			ids[src.ID] = id
		} else {
			contents[src.ID] = id
		}
	}

	var deleted = false
	err = r.f.db.WithTx(r.f.ctx, func(dbh *db.DbHandler) error {
		f := r.f.withDb(dbh)
		if conflictResolution == ResourceBindConflictResolutionOverwrite {
			if _, err := destParent.DeleteChildRecursive(destName, false); err == nil {
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
		return dbh.UpdateResourceModified(f.ctx, destParent.ID())
	})

	if err == nil {
		func() {
			for k, v := range contents {
				if err := r.f.cs.CopyContents(k, v); err != nil {
					logrus.Warn("unable to copy " + k.String() + " to " + v.String() + ": " + err.Error())
				}
			}

		}()
	}

	parentID := destParent.ID()
	var info = ResourceInfo{
		id:            id,
		parentID:      &parentID,
		name:          destName,
		dir:           r.Dir(),
		created:       time.Now(),
		modified:      time.Now(),
		deleted:       nil,
		contentSize:   r.ContentSize(),
		contentType:   r.ContentType(),
		contentSHA256: r.ContentSHA256(),
		permissions:   nil,
		publinks:      nil,
	}
	if destParent.Path() == "/" {
		info.path = "/" + info.name
	} else {
		info.path = destParent.Path() + "/" + info.name
	}

	ancestry := make([]ResourceInfo, len(destParent.Ancestors)+1)
	copy(ancestry, destParent.Ancestors)
	ancestry = append(ancestry, r.Info)
	created := Resource{
		f:              r.f,
		Ancestors:      ancestry,
		Info:           info,
		userPermission: destParent.userPermission,
	}
	return created, deleted, err
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

	name := pathOrUUID[index+1:]
	if name == "" {
		name = src.Name()
	} else if CheckNameInvalid(name) {
		return Resource{}, "", ErrResourceNameInvalid
	}

	var parentID = *src.ParentID()
	if index != 0 {
		if id, err := uuid.Parse(pathOrUUID[0:index]); err != nil {
			return Resource{}, "", err
		} else {
			parentID = id
		}
	}

	if res, err := f.ResourceByID(parentID); err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, "", err
	} else {
		return res, name, nil
	}

}
