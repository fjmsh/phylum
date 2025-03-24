package fs

import (
	"errors"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

type copySrcDest struct {
	src  uuid.UUID
	dest uuid.UUID
}

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
	if res, err := r.f.db.GetAncestors(r.f.ctx, destParent.ID()); err != nil {
		return Resource{}, false, err
	} else {
		for i := 1; i < len(res); i++ {
			if res[i].ID == r.ID() {
				return Resource{}, false, ErrResourceMoveTargetSubdirectory
			}
		}
	}

	var res Resource
	var deleted = false
	return res, deleted, r.f.runInTx(func(f filesystem) error {
		if conflictResolution == ResourceBindConflictResolutionOverwrite || conflictResolution == ResourceBindConflictResolutionDelete {
			if _, err := destParent.DeleteChildRecursive(destName); err == nil {
				deleted = true
			} else if !errors.Is(err, ErrResourceNotFound) {
				return err
			}
		}
		if result, err := f.db.UpdateResourceNameParent(f.ctx, db.UpdateResourceNameParentParams{ID: r.ID(), Name: destName, Parent: destParent.ID()}); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			return err
		} else {
			if err := f.db.RecomputePermissions(r.f.ctx, r.ID()); err != nil {
				return err
			}
			res = ResourceFromDB(result)
			res.f = r.f
			res.userPermission = r.userPermission
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

	var tree []db.Resource
	if recursive && r.Dir() {
		var err error
		tree, err = r.f.db.ReadDir(r.f.ctx, db.ReadDirParams{ResourceID: r.ID(), MinDepth: 1, MaxDepth: 1000})
		if err != nil {
			return Resource{}, false, err
		}
	}
	children := make([]db.CreateResourcesParams, 0, len(tree))
	var contents []copySrcDest
	newIDs := make(map[uuid.UUID]uuid.UUID)

	var res Resource
	created := false
	deleted := false
	err = r.f.runInTx(func(f filesystem) error {
		res, created, deleted, err = f.createResource(
			id,
			destParent.ID(),
			destName,
			r.Dir(),
			r.contentLength,
			r.contentType,
			r.contentSHA256,
			conflictResolution,
		)
		// createResource may return an already existing resources, depending on the specified conflictResolution
		id = res.id
		if err == nil && r.ID() == id {
			err = ErrResourceCopyTargetSelf
		}
		if err != nil {
			return err
		}

		if res.dir {
			newIDs[r.ID()] = id
		} else {
			contents = append(contents, copySrcDest{src: r.ID(), dest: id})
		}

		for _, src := range tree {
			id, _ := uuid.NewV7()
			parent := newIDs[*src.Parent]

			children = append(children, db.CreateResourcesParams{
				ID:            id,
				Parent:        parent,
				Name:          src.Name,
				Dir:           src.Dir,
				ContentLength: src.ContentLength,
				ContentType:   src.ContentType,
				ContentSha256: src.ContentSha256,
			})

			if src.Dir {
				newIDs[src.ID] = id
			} else {
				contents = append(contents, copySrcDest{src: src.ID, dest: id})
			}
		}

		if _, err := f.db.CreateResources(f.ctx, children); err != nil {
			return err
		}
		if err := f.db.RecomputePermissions(r.f.ctx, id); err != nil {
			return err
		}
		if created {
			return f.db.UpdateResourceModified(f.ctx, destParent.ID())
		}
		return nil
	})

	if err == nil {
		func() {
			for _, c := range contents {
				if err := r.f.cs.CopyContents(c.src, c.dest); err != nil {
					logrus.Warn("unable to copy " + c.src.String() + " to " + c.dest.String() + ": " + err.Error())
				}
			}

		}()
	} else {
		return Resource{}, false, err
	}

	res.f = r.f
	res.userPermission = destParent.userPermission
	return res, deleted, err
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
