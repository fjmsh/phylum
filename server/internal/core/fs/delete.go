package fs

import (
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func (r Resource) DeleteChildRecursive(name string, hardDelete bool) error {
	if !r.hasPermission(PermissionWrite) {
		return ErrInsufficientPermissions
	}

	id, err := r.f.db.ChildResourceIDByName(r.f.ctx, db.ChildResourceIDByNameParams{Parent: r.ID, Name: name})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrResourceNotFound
		}
		return err
	}
	return r.f.deleteRecursive(id, r.ID, hardDelete)
}

func (r Resource) DeleteRecursive(hardDelete bool) error {
	if r.ParentID == nil {
		return ErrInsufficientPermissions
	}
	parent, err := r.f.ResourceByID(*r.ParentID)
	if err != nil {
		return err
	}
	if !parent.hasPermission(PermissionWrite) {
		return ErrInsufficientPermissions
	}
	return r.f.deleteRecursive(r.ID, parent.ID, hardDelete)
}

func (f filesystem) deleteRecursive(id, parent uuid.UUID, hardDelete bool) error {
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
