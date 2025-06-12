package core

import (
	"errors"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/sirupsen/logrus"
)

func (f fileSystem) Move(r Resource, target string, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
	var res Resource
	var deleted bool
	var err error
	err = f.runInTx(func(f txFileSystem) error {
		res, deleted, err = f.Move(r, target, conflictResolution)
		return err
	})
	return res, deleted, err
}

func (f txFileSystem) Move(r Resource, target string, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
	// Check source directory permissions
	if r.deleted.Valid {
		return Resource{}, false, ErrResourceDeleted
	}
	if !r.parentID.Valid {
		return Resource{}, false, ErrInsufficientPermissions
	}
	parent, err := f.ResourceByID(r.parentID.Bytes)
	if err != nil {
		return Resource{}, false, err
	}
	if err := parent.checkPermission(f.user, PermissionRead|PermissionWrite); err != nil {
		return Resource{}, false, err
	}

	// Check destParent directory permissions (if applicable)
	destName, destParent, err := f.targetNameParentByPathWithRoot(target, r)
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
	if err := destParent.checkPermission(f.user, PermissionWrite); err != nil {
		return Resource{}, false, err
	}
	if destParent.id == r.id {
		return Resource{}, false, ErrResourceMoveTargetSubdirectory
	}
	if destAncestors, err := f.GetAncestors(r); err != nil {
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
	if conflictResolution == ResourceBindConflictResolutionOverwrite || conflictResolution == ResourceBindConflictResolutionDelete {
		if id, _, err := childResourceIDByName(f.db, r.ID(), destName); err != nil {
			if !errors.Is(err, ErrResourceNotFound) {
				return res, deleted, err
			}
		} else if err := softDelete(f.db, id); err != nil {
			return res, deleted, err
		} else {
			deleted = true
		}
	}
	newParentID := pgtype.UUID{
		Bytes: destParent.id,
		Valid: true,
	}
	if r.parentID.Bytes == destParent.id {
		newParentID = pgtype.UUID{}
	}
	if err := updateResourceNameParent(f.db, r.id, destName, newParentID); err != nil {
		return res, deleted, err
	} else {
		res = r
		res.name = destName
		if newParentID.Valid {
			if err := recomputePermissions(f.db, r.id); err != nil {
				return res, deleted, err
			}
			res.parentID = newParentID
			res.visibleParent = newParentID
		}
		return res, deleted, nil
	}
}

func updateResourceNameParent(db db.TxHandler, id uuid.UUID, name string, parent pgtype.UUID) error {
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

	if _, err := db.Exec(q, args...); err != nil {
		if strings.Contains(err.Error(), "unique_member_resource_name") {
			return ErrResourceNameConflict
		}
		return err
	}
	return nil
}

func (f fileSystem) Copy(r Resource, target string, id uuid.UUID, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
	var res Resource
	var deleted bool
	var err error
	err = f.runInTx(func(f txFileSystem) error {
		res, deleted, err = f.Copy(r, target, id, recursive, conflictResolution)
		return err
	})
	return res, deleted, err
}

func (f txFileSystem) Copy(r Resource, target string, id uuid.UUID, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
	// Check source directory permissions
	if err := r.checkPermission(f.user, PermissionWrite); err != nil {
		return Resource{}, false, err
	}
	if r.deleted.Valid {
		return Resource{}, false, ErrResourceDeleted
	}

	// Check dest directory permissions
	destName, destParent, err := f.targetNameParentByPathWithRoot(target, r)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, false, err
	}
	if !destParent.dir {
		return Resource{}, false, ErrResourceNotCollection

	}
	if err := destParent.checkPermission(f.user, PermissionWrite); err != nil {
		return Resource{}, false, err
	}

	var tree []Resource
	if recursive && r.dir {
		var err error
		tree, err = f.ReadDir(r, true)
		if err != nil {
			return Resource{}, false, err
		}
	}
	children := make([]insertResourcesFastParams, 0, len(tree))
	var contents []copyParams
	newIDs := make(map[uuid.UUID]uuid.UUID)

	targetRoot, created, deleted, err := resolveConflictAndInsertResource(
		f.db,
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
		return Resource{}, false, err
	}

	if targetRoot.dir {
		newIDs[r.id] = id
	} else {
		contents = append(contents, copyParams{
			src:          r.latestVersionInfo,
			destResource: id,
		})
	}

	for _, src := range tree {
		id, _ := uuid.NewV7()
		parent := newIDs[src.parentID.Bytes]

		children = append(children, insertResourcesFastParams{
			ID:     id,
			Parent: parent,
			Name:   src.name,
			Dir:    src.dir,
		})

		if src.dir {
			newIDs[src.id] = id
		} else {
			contents = append(contents, copyParams{
				src:          src.latestVersionInfo,
				destResource: id,
			})
		}
	}

	if _, err := insertResourcesFast(f.db, children); err != nil {
		return Resource{}, false, err
	}
	if err := recomputePermissions(f.db, id); err != nil {
		return Resource{}, false, err
	}
	if created {
		if err := updateResourceModified(f.db, destParent.ID()); err != nil {
			return Resource{}, false, err
		}
	}

	func() {
		// TODO: #jobs
		for _, c := range contents {
			if err := f.copyContents(c); err != nil {
				logrus.Warn("unable to copy " + c.src.ID.String() + " to " + c.destResource.String() + ": " + err.Error())
			}
		}

	}()

	// TODO: #verify this shouldn't be necessary
	// targetRoot.visibleParent = pgtype.UUID{
	// 	Bytes: destParent.id,
	// 	Valid: true,
	// }
	return targetRoot, deleted, err
}

type copyParams struct {
	src          VersionInfo
	destResource uuid.UUID
}

// TODO: #implement copyContents
func (f txFileSystem) copyContents(params copyParams) error {
	versionID, _ := uuid.NewV7()

	if err := insertResourceVersion(f.db, params.destResource, versionID, params.src.Size, params.src.MimeType, params.src.SHA256); err != nil {
		return errors.New("failed to create version for " + params.destResource.String() + ": " + err.Error())
	}

	return errors.New("CopyContents not implemented")

	// in, err := f.OpenRead(params.SrcVersion, 0, -1)
	// if err != nil {
	// 	return uuid.Nil, errors.New("Unable to open " + params.SrcVersion.String() + ": " + err.Error())
	// }
	// defer in.Close()
	// id, _ := uuid.NewV7()

	// out, err := s.OpenWrite(id, nil, nil)
	// if err != nil {
	// 	return uuid.Nil, errors.New("Unable to open " + id.String() + ": " + err.Error())
	// }
	// defer out.Close()

	// _, err = io.Copy(out, in)
	// return id, err
}
