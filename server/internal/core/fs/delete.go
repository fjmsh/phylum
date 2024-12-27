package fs

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func (r Resource) DeleteChildRecursive(name string, hardDelete bool) (ResourceInfo, error) {
	if !r.hasPermission(PermissionWrite) {
		return ResourceInfo{}, ErrInsufficientPermissions
	}

	c, err := r.f.db.ChildResourceByName(r.f.ctx, db.ChildResourceByNameParams{Parent: r.ID(), Name: name})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrResourceNotFound
		}
		return ResourceInfo{}, err
	}
	if err := r.f.deleteRecursive(c.ID, r.ID(), hardDelete, false); err != nil {
		return ResourceInfo{}, err
	}
	deleted := time.Now()
	r.Info.deleted = &deleted
	return r.Info, nil
}

func (r Resource) DeleteRecursive(hardDelete bool) (ResourceInfo, error) {
	if r.ParentID() == nil {
		return ResourceInfo{}, ErrInsufficientPermissions
	}
	parent, err := r.f.ResourceByID(*r.ParentID())
	if err == nil && !parent.hasPermission(PermissionWrite) {
		err = ErrInsufficientPermissions
	}
	if err != nil {
		return ResourceInfo{}, err
	}
	if err := r.f.deleteRecursive(r.ID(), r.ID(), hardDelete, false); err != nil {
		return ResourceInfo{}, err
	}
	deleted := time.Now()
	r.Info.deleted = &deleted
	return r.Info, nil
}

func (f filesystem) deleteRecursive(id, parent uuid.UUID, hardDelete, preserveRoot bool) error {
	var deleted []db.DeleteRecursiveRow
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		if deleted, err = d.DeleteRecursive(f.ctx, db.DeleteRecursiveParams{ID: id, PreserveRoot: preserveRoot}); err != nil {
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
