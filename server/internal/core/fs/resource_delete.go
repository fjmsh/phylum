package fs

import (
	"context"
	"errors"
	"fmt"
	"path"
	"strings"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func (r Resource) DeleteChildRecursive(name string) (Resource, error) {
	if !r.hasPermission(PermissionWrite) {
		return Resource{}, ErrInsufficientPermissions
	}

	c, err := r.f.ChildResourceByName(r.ID(), name)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrResourceNotFound
		}
		return Resource{}, err
	}
	if err := r.f.deleteRecursive(c.ID(), r.ID(), true, false); err != nil {
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
	if err := r.f.deleteRecursive(r.ID(), *r.ParentID(), softDelete, false); err != nil {
		return Resource{}, err
	}
	deleted := time.Now()
	r.deleted = &deleted
	return r, nil
}

// RestoreDeleted restores a previously deleted resources
// Checks:
//   - Parent must not be deleted
//   - Parent must have write permission
//   - No name conflict with exiting resource
func (r Resource) RestoreDeleted(parentPathOrUUID string, name string, autoRename bool) (res Resource, count int, size int64, err error) {
	var p Resource
	if parentPathOrUUID == "" {
		p, err = r.f.ResourceByID(*r.parentID)
	} else {
		p, err = r.f.ResourceByPathOrUUID(parentPathOrUUID)
	}
	if err == ErrResourceNotFound {
		err = ErrParentNotFound
	}
	if err != nil {
		return
	}

	if p.deleted != nil {
		err = ErrParentDeleted
		return
	}
	if !p.hasPermission(PermissionWrite) {
		err = ErrInsufficientPermissions
		return
	}

	if name == "" {
		name = r.name
	}
	_, err = r.f.ChildResourceByName(p.id, name)
	if autoRename && err == nil {
		ext := path.Ext(name)
		basename := name[:len(name)-len(ext)]
		counter := 1
		for {
			name = fmt.Sprintf("%s (%d)%s", basename, counter, ext)
			if _, err = r.f.ChildResourceByName(p.id, name); err == nil {
				counter++
			} else {
				break
			}
		}
	}
	if err != pgx.ErrNoRows {
		if err == nil {
			err = ErrResourceNameConflict
		}
		return
	}

	err = r.f.runInTx(func(f filesystem) error {
		if p.id != *r.parentID || r.name != name {
			if update, err := f.db.UpdateResourceNameParent(f.ctx, db.UpdateResourceNameParentParams{ID: r.ID(), Name: name, Parent: p.id}); err != nil {
				if strings.Contains(err.Error(), "unique_member_resource_name") {
					return ErrResourceNameConflict
				}
				return err
			} else {
				r.name = update.Name
				r.parentID = update.Parent
			}
		}
		if del, err := f.markNotDeleted(f.ctx, r.id); err != nil {
			return err
		} else {
			count = len(del)
			for _, l := range del {
				size += l
			}
		}

		return f.db.RecomputePermissions(f.ctx, r.ID())
	})
	res = r
	return
}

func (f filesystem) deleteRecursive(id, parent uuid.UUID, softDelete, preserveRoot bool) error {
	var ids uuid.UUIDs
	err := f.runInTx(func(f filesystem) error {
		var err error
		if _, ids, err = f.markDeleted(id, softDelete, preserveRoot); err != nil {
			return err
		}

		return f.db.UpdateResourceModified(f.ctx, parent)
	})

	if err == nil && !softDelete {
		errors := f.cs.DeleteAll(ids)
		for _, err := range errors {
			logrus.Warn(err)
		}
	}

	return err
}

func (f filesystem) markDeleted(id uuid.UUID, softDelete, excludeRoot bool) (int, []uuid.UUID, error) {
	r, _, q := selectResourceTree(id, excludeRoot, !softDelete)

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
			Returning(r.Col("id"), r.Col("dir")).
			ToSQL()
	} else {
		query, params, _ = q.
			Delete().
			Returning(r.Col("id"), r.Col("dir")).
			ToSQL()
	}

	return collectNonDirResourceIDs(f.db.Query(f.ctx, query, params...))
}

func (f filesystem) markNotDeleted(ctx context.Context, id uuid.UUID) ([]int64, error) {
	r, _, s := selectResourceTree(id, false, false)
	q := s.Update().Set(
		goqu.Record{
			"modified": goqu.L("NOW()"),
			"deleted":  nil,
		}).
		Returning(r.Col("content_length"))

	query, params, _ := q.ToSQL()

	rows, err := f.db.Query(ctx, query, params...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []int64
	for rows.Next() {
		var content_length int64
		if err := rows.Scan(&content_length); err != nil {
			return nil, err
		}
		items = append(items, content_length)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}
