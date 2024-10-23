package fs

import (
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func (f filesystem) DeleteChildRecursive(r Resource, name string, hardDelete bool) error {
	if !r.hasPermission(PermissionWrite) {
		return ErrInsufficientPermissions
	}

	id, err := f.db.ChildResourceIDByName(f.ctx, db.ChildResourceIDByNameParams{Parent: r.ID, Name: name})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrResourceNotFound
		}
		return err
	}
	return deleteRecursive(f, id, r.ID, hardDelete)
}

func (f filesystem) DeleteRecursive(r Resource, hardDelete bool) error {
	if r.ParentID == nil {
		return ErrInsufficientPermissions
	}
	parent, err := f.ResourceByID(*r.ParentID)
	if err != nil {
		return err
	}
	if !parent.hasPermission(PermissionWrite) {
		return ErrInsufficientPermissions
	}
	return deleteRecursive(f, r.ID, parent.ID, hardDelete)
}

func deleteRecursive(f filesystem, id, parent uuid.UUID, hardDelete bool) error {
	var deleted []db.DeleteRecursiveRow
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		if deleted, err = d.DeleteRecursive(f.ctx, id); err != nil {
			return err
		}

		return d.UpdateResourceModified(f.ctx, parent)
	})

	if err == nil && hardDelete {
		errors := f.cs.DeleteAll(deleted)
		for _, err := range errors {
			logrus.Warn(err)
		}
	}

	return err

}
