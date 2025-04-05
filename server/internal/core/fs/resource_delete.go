package fs

import (
	"errors"
	"fmt"
	"path"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/sirupsen/logrus"
)

func (r Resource) DeleteChildRecursive(name string) (Resource, error) {
	if !r.hasPermission(PermissionWrite) {
		return Resource{}, ErrInsufficientPermissions
	}

	c, err := r.f.childResourceByName(r.ID(), name)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrResourceNotFound
		}
		return Resource{}, err
	}
	if err := r.f.deleteRecursive(c.ID(), r.ID(), true, false); err != nil {
		return Resource{}, err
	}
	r.deleted = pgtype.Timestamp{
		Valid: true,
		Time:  time.Now(),
	}
	return r, nil
}

func (r Resource) DeleteRecursive(softDelete bool) (Resource, error) {
	if r.ParentID() == uuid.Nil {
		return Resource{}, ErrInsufficientPermissions
	}
	parent, err := r.f.ResourceByID(r.ParentID())
	if err == nil && !parent.hasPermission(PermissionWrite) {
		err = ErrInsufficientPermissions
	}
	if err != nil {
		return Resource{}, err
	}
	if err := r.f.deleteRecursive(r.ID(), r.ParentID(), softDelete, false); err != nil {
		return Resource{}, err
	}
	if softDelete {
		r.deleted = pgtype.Timestamp{
			Valid: true,
			Time:  time.Now(),
		}
		return r, nil
	}
	return Resource{}, nil
}

// RestoreDeleted restores a previously deleted resources
// Checks:
//   - Parent must not be deleted
//   - Parent must have write permission
//   - No name conflict with exiting resource
func (r Resource) RestoreDeleted(parentPathOrUUID string, name string, autoRename bool) (res Resource, count int, size int64, err error) {
	var p Resource
	if parentPathOrUUID == "" {
		p, err = r.f.ResourceByID(r.parentID)
	} else {
		p, err = r.f.ResourceByPathOrUUID(parentPathOrUUID)
	}
	if err == ErrResourceNotFound {
		err = ErrParentNotFound
	}
	if err != nil {
		return
	}

	if p.deleted.Valid {
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
	_, err = r.f.childResourceByName(p.id, name)
	if autoRename && err == nil {
		ext := path.Ext(name)
		basename := name[:len(name)-len(ext)]
		counter := 1
		for {
			name = fmt.Sprintf("%s (%d)%s", basename, counter, ext)
			if _, err = r.f.childResourceByName(p.id, name); err == nil {
				counter++
			} else {
				break
			}
		}
	}
	if err != ErrResourceNotFound {
		if err == nil {
			err = ErrResourceNameConflict
		}
		return
	}

	err = r.f.runInTx(func(f filesystem) error {
		if p.id != r.parentID || r.name != name {
			if err := f.updateResourceNameParent(r.ID(), name, p.id); err != nil {
				return err
			} else {
				r.name = name
				r.parentID = p.id
			}
		}
		if del, err := f.markNotDeleted(r.id); err != nil {
			return err
		} else {
			count = len(del)
			for _, l := range del {
				size += l
			}
		}

		return f.recomputePermissions(r.id)
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

		return f.updateResourceModified(parent)
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
	r, _, q := selectResourceTree(id, excludeRoot, !softDelete, false)

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

	return collectNonDirResourceIDs(f.db.Query(query, params...))
}

func (f filesystem) markNotDeleted(id uuid.UUID) ([]int64, error) {
	r, _, s := selectResourceTree(id, false, false, false)
	q := s.Update().Set(
		goqu.Record{
			"modified": goqu.L("NOW()"),
			"deleted":  nil,
		}).
		Returning(r.Col("content_length"))

	query, params, _ := q.ToSQL()

	rows, err := f.db.Query(query, params...)
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
