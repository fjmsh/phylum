package fs

import (
	"errors"
	"strings"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

type copySrcDest struct {
	src  uuid.UUID
	dest uuid.UUID
}

func (r Resource) Move(target string, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
	if r.ParentID() == uuid.Nil {
		return Resource{}, false, ErrInsufficientPermissions
	}

	// Check source directory permissions
	parent, err := r.f.ResourceByID(r.ParentID())
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
	if r.parentID == destParent.id && r.name == destName {
		return r, false, nil
	}
	if !destParent.Dir() {
		return Resource{}, false, ErrResourceNotCollection
	}
	if !destParent.hasPermission(PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}
	if destAncestors, err := destParent.GetAncestors(); err != nil {
		return Resource{}, false, err
	} else {
		for _, a := range destAncestors {
			if a.ID == r.ID() {
				return Resource{}, false, ErrResourceMoveTargetSubdirectory
			}
		}
	}

	var res Resource
	var deleted = false
	return res, deleted, r.f.runInTx(func(f filesystem) error {
		if conflictResolution == ResourceBindConflictResolutionOverwrite || conflictResolution == ResourceBindConflictResolutionDelete {
			// TODO: Use f directly instead of Resource
			if _, err := destParent.DeleteChildRecursive(destName); err == nil {
				deleted = true
			} else if !errors.Is(err, ErrResourceNotFound) {
				return err
			}
		}
		if err := f.updateResourceNameParent(r.id, destName, destParent.ID()); err != nil {
			return err
		} else {
			if err := f.recomputePermissions(r.id); err != nil {
				return err
			}
			res = r
			res.name = destName
			res.parentID = destParent.id
			return nil
		}
	})
}

func (f filesystem) updateResourceNameParent(id uuid.UUID, name string, parent uuid.UUID) error {
	const q = `UPDATE resources
SET
    name = CASE WHEN ($1::TEXT = '') THEN name ELSE $1::TEXT END,
    parent = CASE WHEN ($2 IS NULL) THEN parent ELSE $2::UUID,
    modified = NOW()
WHERE id = $1::UUID `

	if _, err := f.db.Exec(f.ctx, q, id, name, &parent); err != nil {
		if strings.Contains(err.Error(), "unique_member_resource_name") {
			return ErrResourceNameConflict
		}
		return err
	}
	return nil
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
	if !destParent.dir {
		return Resource{}, false, ErrResourceNotCollection

	}
	if !destParent.hasPermission(PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}

	var tree []Resource
	if recursive && r.dir {
		var err error
		tree, err = r.ReadDir(true)
		if err != nil {
			return Resource{}, false, err
		}
	}
	children := make([]CreateResourcesParams, 0, len(tree))
	var contents []copySrcDest
	newIDs := make(map[uuid.UUID]uuid.UUID)

	var targetRoot Resource
	created := false
	deleted := false
	err = r.f.runInTx(func(f filesystem) error {
		targetRoot, created, deleted, err = f.createResource(
			id,
			destParent.id,
			destName,
			r.dir,
			r.contentLength,
			r.contentType,
			r.contentSHA256,
			r.permissions,
			conflictResolution,
		)
		// createResource may return an already existing resources, depending on the specified conflictResolution
		id = targetRoot.id
		if err == nil && r.id == id {
			err = ErrResourceCopyTargetSelf
		}
		if err != nil {
			return err
		}

		if targetRoot.dir {
			newIDs[r.id] = id
		} else {
			contents = append(contents, copySrcDest{src: r.id, dest: id})
		}

		for _, src := range tree {
			id, _ := uuid.NewV7()
			parent := newIDs[src.parentID]

			children = append(children, CreateResourcesParams{
				ID:            id,
				Parent:        parent,
				Name:          src.name,
				Dir:           src.dir,
				ContentLength: src.contentLength,
				ContentType:   src.contentType,
				ContentSha256: src.contentSHA256,
			})

			if src.dir {
				newIDs[src.id] = id
			} else {
				contents = append(contents, copySrcDest{src: src.id, dest: id})
			}
		}

		if _, err := f.CreateResources(children); err != nil {
			return err
		}
		if err := f.recomputePermissions(id); err != nil {
			return err
		}
		if created {
			return f.updateResourceModified(destParent.ID())
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

	targetRoot.f = r.f
	targetRoot.userPermission = destParent.userPermission
	return targetRoot, deleted, err
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

	var parentID = src.ParentID()
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
