package fs

import (
	"errors"
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/sirupsen/logrus"
)

func (r Resource) Move(target string, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
	// Check source directory permissions
	if r.deleted.Valid {
		return Resource{}, false, ErrResourceDeleted
	}
	if !r.parentID.Valid {
		return Resource{}, false, ErrInsufficientPermissions
	}
	parent, err := r.f.ResourceByID(r.parentID.Bytes)
	if err != nil {
		return Resource{}, false, err
	}
	if !parent.hasPermission(PermissionRead | PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}

	// Check destParent directory permissions (if applicable)
	destName, destParent, err := r.targetNameParentByPathWithRoot(target)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, false, err
	}
	if r.parentID.Bytes == destParent.id && r.name == destName {
		return r, false, nil
	}
	if !destParent.Dir() {
		return Resource{}, false, ErrResourceNotCollection
	}
	if !destParent.hasPermission(PermissionWrite) {
		return Resource{}, false, ErrInsufficientPermissions
	}
	if destParent.id == r.id {
		return Resource{}, false, ErrResourceMoveTargetSubdirectory
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
		newParentID := pgtype.UUID{
			Bytes: destParent.id,
			Valid: true,
		}
		if r.parentID.Bytes == destParent.id {
			newParentID = pgtype.UUID{}
		}
		if err := f.updateResourceNameParent(r.id, destName, newParentID); err != nil {
			return err
		} else {
			res = r
			res.name = destName
			if newParentID.Valid {
				if err := f.recomputePermissions(r.id); err != nil {
					return err
				}
				res.parentID = newParentID
				res.visibleParent = newParentID
			}
			return nil
		}
	})
}

func (f filesystem) updateResourceNameParent(id uuid.UUID, name string, parent pgtype.UUID) error {
	updates := goqu.Record{
		"modified": goqu.L("NOW()"),
	}
	if name != "" {
		updates["name"] = name
	}
	if parent.Valid {
		updates["parent"] = parent
	}
	q, args, _ := pg.Update("resources").Where(goqu.C("id").Eq(id)).Set(updates).ToSQL()

	if _, err := f.db.Exec(q, args...); err != nil {
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
	if r.deleted.Valid {
		return Resource{}, false, ErrResourceDeleted
	}

	// Check dest directory permissions
	destName, destParent, err := r.targetNameParentByPathWithRoot(target)
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
	var contents []storage.ContentsCopy
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
			destParent.permissions,
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
			if version, err := r.LatestVersion(); err != nil {
				logrus.Warn("Unable to copy " + r.id.String() + ": " + err.Error())
			} else {
				contents = append(contents, storage.ContentsCopy{
					SrcVersion:   version.ID,
					DestResource: id,
					Size:         version.Size,
					MimeType:     version.MimeType,
					SHA256:       version.SHA256,
				})
			}
		}

		for _, src := range tree {
			id, _ := uuid.NewV7()
			parent := newIDs[src.parentID.Bytes]

			children = append(children, CreateResourcesParams{
				ID:     id,
				Parent: parent,
				Name:   src.name,
				Dir:    src.dir,
			})

			if src.dir {
				newIDs[src.id] = id
			} else {
				if version, err := src.LatestVersion(); err != nil {
					logrus.Warn("Unable to copy " + src.id.String() + ": " + err.Error())
				} else {
					contents = append(contents, storage.ContentsCopy{
						SrcVersion:   version.ID,
						DestResource: id,
						Size:         version.Size,
						MimeType:     version.MimeType,
						SHA256:       version.SHA256,
					})
				}
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
				if id, err := r.f.cs.CopyContents(c); err != nil {
					logrus.Warn("unable to copy " + c.SrcVersion.String() + " to " + c.DestResource.String() + ": " + err.Error())
				} else if err := r.f.createResourceVersion(r.id, id, c.Size, c.MimeType, c.SHA256); err != nil {
					logrus.Warn("unable to create version for " + c.DestResource.String() + ": " + err.Error())
				}
			}

		}()
	} else {
		return Resource{}, false, err
	}

	targetRoot.visibleParent = pgtype.UUID{
		Bytes: destParent.id,
		Valid: true,
	}
	targetRoot.f = r.f
	targetRoot.userPermission = destParent.userPermission
	return targetRoot, deleted, err
}
