package core

import (
	"fmt"
	"path"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f filesystem) Trash(r Resource) (Resource, error) {
	if !r.parentID.Valid {
		return Resource{}, ErrInsufficientPermissions
	}
	if r.deleted.Valid {
		return Resource{}, ErrResourceDeleted
	}
	parent, err := f.ResourceByID(r.parentID.Bytes)
	if err == nil && !parent.hasPermission(PermissionWrite) {
		err = ErrInsufficientPermissions
	}
	if err != nil {
		return Resource{}, err
	}

	err = f.runInTx(func(f filesystem) error {
		if err := softDelete(f.db, r.id); err != nil {
			return err
		}

		return f.updateResourceModified(r.parentID.Bytes)
	})
	if err != nil {
		return Resource{}, err
	}

	r.deleted = pgtype.Timestamp{
		Valid: true,
		Time:  time.Now(),
	}
	return r, nil
}

func softDelete(d db.Handler, id uuid.UUID) error {
	return d.RunInTx(func(db db.Handler) error {
		// Select all descendants, not including deleted ones
		_, _, q := selectResourceTree(id, false, false, false)

		// Set modified and deleted
		query, params, _ := q.
			Update().
			Set(
				goqu.Record{
					"modified": goqu.L("NOW()"),
					"deleted":  goqu.L("NOW()"),
				}).
			ToSQL()

		if _, err := db.Exec(query, params...); err != nil {
			return err
		}

		// Add to trash
		query, params, _ = pg.Insert(goqu.T("trash")).Cols("id").Vals(goqu.Vals{id}).ToSQL()
		_, err := db.Exec(query, params...)

		return err
	})
}

func (f filesystem) softDeleteChildren(id, parent uuid.UUID) error {
	err := f.runInTx(func(f filesystem) error {
		// Select non-deleted descendents excluding the tree root (id)
		_, _, s := selectResourceTree(id, true, false, false)

		// Mark deleted
		q, params, _ := s.Update().
			Set(
				goqu.Record{
					"modified": goqu.L("NOW()"),
					"deleted":  goqu.L("NOW()"),
				}).
			ToSQL()
		if _, err := f.db.Exec(q, params...); err != nil {
			return err
		}

		// Add children to trash
		insert := pg.
			Insert(goqu.T("trash")).
			Cols("id").
			FromQuery(pg.
				From("resources").
				Select("id").
				Where(goqu.C("parent").Eq(id)))
		q, args, _ := insert.ToSQL()
		if _, err := f.db.Exec(q, args...); err != nil {
			return err
		}

		return f.updateResourceModified(parent)
	})

	return err
}

func (f filesystem) HardDelete(r Resource) error {
	if !r.parentID.Valid {
		return ErrInsufficientPermissions
	}
	parent, err := f.ResourceByID(r.parentID.Bytes)
	if err == nil && !parent.hasPermission(PermissionWrite) {
		return ErrInsufficientPermissions
	}
	if err != nil {
		return err
	}
	return f.runInTx(func(f filesystem) error {
		// Select all descendants, including deleted resources
		v := goqu.T("resource_versions").As("v")
		r, _, q := selectResourceTree(r.id, false, true, false)

		// Delete resources and versions from db, returning version ids
		query, params, _ := q.
			LeftJoin(v, goqu.On(r.Col("id").Eq(v.Col("resource_id")))).
			Delete().
			Returning(v.Col("id")).
			ToSQL()

		if rows, err := f.db.Query(query, params...); err != nil {
			return err
		} else if ids, err := pgx.CollectRows(rows, scanID); err != nil {
			return err
		} else if err := f.updateResourceModified(parent.id); err != nil {
			return err
		} else {
			jobs.DeleteAllVersionContents(ids)
		}
		return nil
	})
}

func scanID(row pgx.CollectableRow) (uuid.UUID, error) {
	var id uuid.UUID
	err := row.Scan(&id)
	return id, err
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
	_, _, err = f.childResourceIDByName(p.id, name)
	if autoRename && err == nil {
		ext := path.Ext(name)
		basename := name[:len(name)-len(ext)]
		counter := 1
		for {
			name = fmt.Sprintf("%s (%d)%s", basename, counter, ext)
			if _, _, err = f.childResourceIDByName(p.id, name); err == nil {
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
