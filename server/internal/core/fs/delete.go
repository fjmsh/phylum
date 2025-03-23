package fs

import (
	"errors"
	"time"

	"github.com/doug-martin/goqu/v9"
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
	var ids uuid.UUIDs
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		if _, ids, err = f.Delete(id, softDelete, preserveRoot); err != nil {
			return err
		}

		return d.UpdateResourceModified(f.ctx, parent)
	})

	if err == nil && !softDelete {
		errors := f.cs.DeleteAll(ids)
		for _, err := range errors {
			logrus.Warn(err)
		}
	}

	return err
}

func (f filesystem) Delete(id uuid.UUID, softDelete, excludeRoot bool) (int, []uuid.UUID, error) {
	idSelect := pg.From("nodes").Select("id")
	if excludeRoot {
		idSelect = idSelect.Where(goqu.C("depth").Gt(0))
	}

	table := goqu.T("resource").As("r")
	nodes := goqu.T("nodes")
	q := selectResourceTree(pg.From(table), nodes, id, !softDelete).
		Where(table.Col("id").Eq(idSelect))

	// table
	var query string
	var params []interface{}
	if softDelete {
		query, params, _ = q.
			Update().
			Set(
				goqu.Record{
					"modified": goqu.L("NOW()"),
					"deleted":  goqu.L("NOW()"),
				}).
			Returning(table.Col("id"), table.Col("dir")).
			ToSQL()
	} else {
		query, params, _ = q.
			Delete().
			Returning(table.Col("id"), table.Col("dir")).
			ToSQL()
	}

	return collectDeletedRows(f.db.Query(f.ctx, query, params...))
}
