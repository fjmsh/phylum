package core

import (
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f filesystem) Delete(r Resource) (Resource, error) {
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

func (f filesystem) DeleteForever(r Resource) error {
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
		r, _, q := selectResourceTree(r.id, false, true, false)

		if err := f.updateResourceModified(parent.id); err != nil {
			return err
			// deleteAllVersions needs to be called last, as it will enqueue the delete jobs
		} else if err := hardDeleteAllVersions(f.db, q, r); err != nil {
			return err
		}
		return nil
	})
}

func collectDeletedVersions(rows pgx.Rows) ([]jobs.DeleteContentsArgs, error) {
	defer rows.Close()

	var result []jobs.DeleteContentsArgs
	var v jobs.DeleteContentsArgs
	var storage pgtype.Text
	var id uuid.UUID
	for rows.Next() {
		err := rows.Scan(&id, &storage)
		if err != nil {
			return nil, err
		}
		if id != uuid.Nil {
			v.Name = id.String()
			result = append(result, v)
		}
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return result, nil
}

// RestoreDeleted restores a previously deleted resources
// Checks:
//   - Parent must not be deleted
//   - Parent must have write permission
//   - No name conflict with exiting resource
func (f filesystem) RestoreDeleted(r Resource, parentPathOrUUID string, name string, autoRename bool) (res Resource, err error) {
	// Locate parent
	var parent Resource
	if parentPathOrUUID == "" {
		if r.parentID.Valid {
			parent, err = f.ResourceByID(r.parentID.Bytes)
		} else {
			err = ErrResourceNotFound
		}
	} else {
		parent, err = f.ResourceByPathWithRoot(parentPathOrUUID)
	}
	if err == ErrResourceNotFound {
		err = ErrParentNotFound
	}
	if err != nil {
		return
	}

	// Make sure parent is not deleted and has write permissions
	if parent.deleted.Valid {
		err = ErrParentDeleted
		return
	}
	if !parent.hasPermission(PermissionWrite) {
		err = ErrInsufficientPermissions
		return
	}

	if name == "" {
		name = r.name
	}
	if name, err = f.detectNameConflict(parent.id, name, autoRename); err != nil {
		return
	}

	err = f.runInTx(func(f filesystem) error {
		q, args, _ := pg.Delete(goqu.T("trash")).Where(goqu.C("id").Eq(r.id)).ToSQL()
		if _, err := f.db.Exec(q, args...); err != nil {
			return err
		}

		if parent.id != r.parentID.Bytes || r.name != name {
			if err := f.updateResourceNameParent(r.ID(), name, pgtype.UUID{Bytes: parent.id, Valid: true}); err != nil {
				return err
			} else {
				r.name = name
				r.parentID = pgtype.UUID{Bytes: parent.id, Valid: true}
				r.visibleParent = r.parentID
			}
		}
		_, _, s := selectResourceTree(r.id, false, false, false)
		query, params, _ := s.Update().Set(
			goqu.Record{
				"modified": goqu.L("NOW()"),
				"deleted":  nil,
			}).ToSQL()

		if _, err := f.db.Exec(query, params...); err != nil {
			return err
		}

		return f.recomputePermissions(r.id)
	})
	r.deleted = pgtype.Timestamp{}
	res = r
	return
}
