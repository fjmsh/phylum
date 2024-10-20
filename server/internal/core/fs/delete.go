package fs

import (
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func (f filesystem) DeleteChildRecursive(r Resource, name string, hardDelete bool) error {
	if result, err := f.db.ChildResourceByName(f.ctx, db.ChildResourceByNameParams{Parent: r.ID, Name: name}); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrResourceNotFound
		}
		return err
	} else {
		child := Resource{
			ID:              result.ID,
			ParentID:        result.Parent,
			Name:            result.Name,
			Dir:             result.Dir,
			Created:         result.Created.Time,
			Modified:        result.Modified.Time,
			Deleted:         nil,
			ContentType:     result.ContentType,
			ContentSize:     result.ContentSize,
			ContentSHA256:   result.ContentSha256,
			Permissions:     string(result.Permissions),
			UserPermissions: r.UserPermissions,
			Path:            r.Path,
			// Not Needed
			// InheritedPermissions: "",
		}
		_, err := f.DeleteRecursive(child, hardDelete)
		return err
	}
}

func (f filesystem) DeleteRecursive(r Resource, hardDelete bool) (uuid.UUIDs, error) {
	if r.UserPermissions < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	// TODO: versioning
	var ids uuid.UUIDs
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		if hardDelete {
			ids, err = d.HardDeleteRecursive(f.ctx, r.ID)
			if err != nil {
				return err
			}
			errors := f.cs.DeleteAll(ids)
			for err := range errors {
				logrus.Warn(err)
			}
		} else {
			if ids, err = d.DeleteRecursive(f.ctx, r.ID); err != nil {
				return err
			}
		}

		parent := r.ParentID
		if parent != nil {
			return d.UpdateResourceModified(f.ctx, *parent)
		}
		return nil
	})

	if err != nil {
		return nil, err
	}

	return ids, nil
}
