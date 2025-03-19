package fs

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func (r Resource) DeleteChildRecursive(name string, softDelete bool) (Resource, error) {
	if !r.hasPermission(PermissionWrite) {
		return Resource{}, ErrInsufficientPermissions
	}

	c, err := r.f.db.ChildResourceByName(r.f.ctx, db.ChildResourceByNameParams{Parent: r.ID(), Name: name})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrResourceNotFound
		}
		return Resource{}, err
	}
	if err := r.f.deleteRecursive(c.ID, r.ID(), softDelete, false); err != nil {
		return Resource{}, err
	}
	deleted := time.Now()
	r.deleted = &deleted
	return r, nil
}

func (r Resource) DeleteRecursive(softDelete bool) (Resource, error) {
	if r.ParentID() == nil {
		return Resource{}, ErrInsufficientPermissions
	}
	parent, err := r.f.ResourceByID(*r.ParentID())
	if err == nil && !parent.hasPermission(PermissionWrite) {
		err = ErrInsufficientPermissions
	}
	if err != nil {
		return Resource{}, err
	}
	if err := r.f.deleteRecursive(r.ID(), r.ID(), softDelete, false); err != nil {
		return Resource{}, err
	}
	deleted := time.Now()
	r.deleted = &deleted
	return r, nil
}

func (f filesystem) deleteRecursive(id, parent uuid.UUID, softDelete, preserveRoot bool) error {
	if softDelete {
		return f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
			var err error
			if err = d.SoftDelete(f.ctx, db.SoftDeleteParams{ID: id, PreserveRoot: preserveRoot}); err != nil {
				return err
			}

			return d.UpdateResourceModified(f.ctx, parent)
		})
	}

	var deleted []db.HardDeleteRow
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		if deleted, err = d.HardDelete(f.ctx, db.HardDeleteParams{ID: id, PreserveRoot: preserveRoot}); err != nil {
			return err
		}

		return d.UpdateResourceModified(f.ctx, parent)
	})

	if err == nil {
		ids := make([]uuid.UUID, len(deleted))
		for i, d := range deleted {
			if !d.Dir {
				ids[i] = d.ID
			}
		}
		errors := f.cs.DeleteAll(ids)
		for _, err := range errors {
			logrus.Warn(err)
		}
	}

	return err
}
