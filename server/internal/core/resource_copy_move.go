package core

import (
	"encoding/json"
	"errors"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f *FileSystem) Move(r Resource, target string, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
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
	if err := f.checkPermission(parent, PermissionRead|PermissionWrite); err != nil {
		return Resource{}, false, err
	}

	// Check destParent directory permissions (if applicable)
	destName, destParent, err := f.targetByPathWithRoot(target, r)
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
	if err := f.checkPermission(destParent, PermissionWrite); err != nil {
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
		if id, _, err := childResourceIDByName(f.db, destParent.id, destName); err != nil {
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

func (f *FileSystem) Copy(r Resource, target string, id uuid.UUID, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
	var res Resource
	var deleted bool
	var err error
	err = f.runInTx(func(f txFileSystem) error {
		res, deleted, err = f.Copy(r, target, id, recursive, conflictResolution)
		return err
	})
	return res, deleted, err
}

func (f txFileSystem) Copy(src Resource, target string, requestedID uuid.UUID, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, bool, error) {
	// Check source directory permissions
	if err := f.checkPermission(src, PermissionRead); err != nil {
		return Resource{}, false, err
	}
	if src.deleted.Valid {
		return Resource{}, false, ErrResourceDeleted
	}

	// Check dest directory permissions
	destName, destParent, err := f.targetByPathWithRoot(target, src)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, false, err
	}
	if !destParent.dir {
		return Resource{}, false, ErrResourceNotCollection

	}
	if err := f.checkPermission(destParent, PermissionWrite); err != nil {
		return Resource{}, false, err
	}

	var tree []Resource
	if recursive && src.dir {
		var err error
		tree, err = f.ReadDir(src, true)
		if err != nil {
			return Resource{}, false, err
		}
	}
	createResources := make([]insertResourcesFastParams, 0, len(tree))
	var createVersions []insertResourceVersionsFastParams
	var copyContents []jobs.CopyContentsArgs
	var copyImgs []jobs.CopyImgsArgs
	var migrateContents []jobs.MigrateArgs
	newIDs := make(map[uuid.UUID]uuid.UUID)

	dest, created, deleted, err := resolveConflictAndInsertResource(
		f.db,
		requestedID,
		destParent.id,
		destName,
		src.dir,
		destParent.permissions,
		conflictResolution,
	)
	// createResource may return an already existing resources, depending on the specified conflictResolution
	if err == nil && src.id == dest.id {
		err = ErrResourceCopyTargetSelf
	}
	if err != nil {
		return Resource{}, false, err
	}

	if src.dir {
		newIDs[src.id] = dest.id
	} else {
		versionID, _ := uuid.NewV7()
		createVersions = append(createVersions, insertResourceVersionsFastParams{
			ID:         versionID,
			ResourceID: dest.id,
			Size:       int32(src.latestVersionInfo.Size),
			MimeType:   src.latestVersionInfo.MimeType,
			SHA256:     src.latestVersionInfo.SHA256,
			ImgRes:     src.latestVersionInfo.ImgRes,
		})
		v := []VersionInfo{{
			ID:       versionID,
			Created:  int(time.Now().Unix()),
			Size:     src.latestVersionInfo.Size,
			MimeType: src.latestVersionInfo.MimeType,
			SHA256:   src.latestVersionInfo.SHA256,
			ImgRes:   src.latestVersionInfo.ImgRes,
		}}
		dest.versions, _ = json.Marshal(v)
		copyImgs = append(copyImgs, jobs.CopyImgsArgs{
			Src:    src.latestVersionInfo.ID,
			Dest:   versionID,
			ImgRes: src.latestVersionInfo.ImgRes,
		})
		copyContents = append(copyContents, jobs.CopyContentsArgs{
			Src:  src.latestVersionInfo.ID,
			Dest: versionID,
		})
		migrateContents = append(migrateContents, jobs.MigrateArgs{
			VersionID: versionID,
		})
	}

	for _, src := range tree {
		resourceID, _ := uuid.NewV7()
		parent := newIDs[src.parentID.Bytes]

		createResources = append(createResources, insertResourcesFastParams{
			ID:     resourceID,
			Parent: parent,
			Name:   src.name,
			Dir:    src.dir,
		})

		if src.dir {
			newIDs[src.id] = resourceID
		} else {
			versionID, _ := uuid.NewV7()
			createVersions = append(createVersions, insertResourceVersionsFastParams{
				ID:         versionID,
				ResourceID: resourceID,
				Size:       int32(src.latestVersionInfo.Size),
				MimeType:   src.latestVersionInfo.MimeType,
				SHA256:     src.latestVersionInfo.SHA256,
				ImgRes:     src.latestVersionInfo.ImgRes,
			})
			copyImgs = append(copyImgs, jobs.CopyImgsArgs{
				Src:    src.latestVersionInfo.ID,
				Dest:   versionID,
				ImgRes: src.latestVersionInfo.ImgRes,
			})
			copyContents = append(copyContents, jobs.CopyContentsArgs{
				Src:  src.latestVersionInfo.ID,
				Dest: versionID,
			})
			migrateContents = append(migrateContents, jobs.MigrateArgs{
				VersionID: versionID,
			})
		}
	}

	if _, err := insertResourcesFast(f.db, createResources); err != nil {
		return Resource{}, false, err
	}
	if _, err := insertResourceVersionsFast(f.db, createVersions); err != nil {
		return Resource{}, false, err
	}
	if err := recomputePermissions(f.db, dest.id); err != nil {
		return Resource{}, false, err
	}
	if created {
		if err := updateResourceModified(f.db, destParent.ID()); err != nil {
			return Resource{}, false, err
		}
	}

	if err := jobs.CopyImgsMany(f.db, copyImgs); err != nil {
		return Resource{}, false, err
	}
	if err := jobs.CopyContents(f.db, copyContents); err != nil {
		return Resource{}, false, err
	}
	if err := jobs.MigrateContentsMany(f.db, migrateContents); err != nil {
		return Resource{}, false, err
	}

	return dest, deleted, err
}
