package core

import (
	"errors"
	"fmt"
	"path"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/jobs"
)

func (f filesystem) deleteChildRecursive(r Resource, name string, softDelete bool) (Resource, error) {
	if !r.hasPermission(PermissionWrite) {
		return Resource{}, ErrInsufficientPermissions
	}
	if r.deleted.Valid {
		return Resource{}, ErrResourceDeleted
	}

	c, err := f.childResourceByName(r.ID(), name)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrResourceNotFound
		}
		return Resource{}, err
	}
	if err := f.deleteRecursive(c.ID(), r.ID(), softDelete, false); err != nil {
		return Resource{}, err
	}
	r.deleted = pgtype.Timestamp{
		Valid: true,
		Time:  time.Now(),
	}
	return r, nil
}

func (f filesystem) DeleteRecursive(r Resource, softDelete bool) (Resource, error) {
	if !r.parentID.Valid {
		return Resource{}, ErrInsufficientPermissions
	}
	if r.deleted.Valid && softDelete {
		return Resource{}, ErrResourceDeleted
	}
	parent, err := f.ResourceByID(r.parentID.Bytes)
	if err == nil && !parent.hasPermission(PermissionWrite) {
		err = ErrInsufficientPermissions
	}
	if err != nil {
		return Resource{}, err
	}
	if err := f.deleteRecursive(r.ID(), r.parentID.Bytes, softDelete, false); err != nil {
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
func (f filesystem) RestoreDeleted(r Resource, parentPathOrUUID string, name string, autoRename bool) (res Resource, count int, size int64, err error) {
	var p Resource
	if parentPathOrUUID == "" {
		if r.parentID.Valid {
			p, err = f.ResourceByID(r.parentID.Bytes)
		} else {
			err = ErrResourceNotFound
		}
	} else {
		p, err = f.ResourceByPathWithRoot(parentPathOrUUID)
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
	_, err = f.childResourceByName(p.id, name)
	if autoRename && err == nil {
		ext := path.Ext(name)
		basename := name[:len(name)-len(ext)]
		counter := 1
		for {
			name = fmt.Sprintf("%s (%d)%s", basename, counter, ext)
			if _, err = f.childResourceByName(p.id, name); err == nil {
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

	err = f.runInTx(func(f filesystem) error {
		q, args, _ := pg.Delete(goqu.T("trash")).Where(goqu.C("id").Eq(r.id)).ToSQL()
		if _, err := f.db.Exec(q, args...); err != nil {
			return err
		}
		if p.id != r.parentID.Bytes || r.name != name {
			if err := f.updateResourceNameParent(r.ID(), name, pgtype.UUID{Bytes: p.id, Valid: true}); err != nil {
				return err
			} else {
				r.name = name
				r.parentID = pgtype.UUID{Bytes: p.id, Valid: true}
				r.visibleParent = r.parentID
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
	r.deleted = pgtype.Timestamp{}
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
		if softDelete {
			// Add to trash
			insert := pg.Insert(goqu.T("trash")).Cols("id")
			if preserveRoot {
				insert = insert.FromQuery(pg.From("resources").Select("id").Where(goqu.C("parent").Eq(id)))
			} else {
				insert = insert.Vals(goqu.Vals{id})
			}
			q, args, _ := insert.ToSQL()
			if _, err := f.db.Exec(q, args...); err != nil {
				return err
			}
		}

		return f.updateResourceModified(parent)
	})

	if err == nil && !softDelete {
		jobs.DeleteAllVersionContents(ids)
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

func collectNonDirResourceIDs(rows pgx.Rows, e error) (total int, ids []uuid.UUID, err error) {
	if e != nil {
		return 0, nil, e
	}
	defer rows.Close()
	var id uuid.UUID
	var dir bool
	for rows.Next() {
		if err := rows.Scan(&id, &dir); err != nil {
			return total, nil, err
		}
		if !dir {
			ids = append(ids, id)
		}
		total++
	}
	err = rows.Err()
	return total, ids, err
}
