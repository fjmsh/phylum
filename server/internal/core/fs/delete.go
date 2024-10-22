package fs

import (
	"errors"

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
		return f.DeleteRecursive(child, hardDelete)
	}
}

func (f filesystem) DeleteRecursive(r Resource, hardDelete bool) error {
	if !r.hasPermission(PermissionWrite) {
		return ErrInsufficientPermissions
	}
	// TODO: versioning
	var deleted []db.DeleteRecursiveRow
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		if deleted, err = d.DeleteRecursive(f.ctx, r.ID); err != nil {
			return err
		}

		parent := r.ParentID
		if parent != nil {
			return d.UpdateResourceModified(f.ctx, *parent)
		}
		return nil
	})

	if err == nil && hardDelete {
		errors := f.cs.DeleteAll(deleted)
		for _, err := range errors {
			logrus.Warn(err)
		}

	}

	return err
}
