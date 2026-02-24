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

func (f *FileSystem) Delete(r Resource) (Resource, error) {
	var res Resource
	err := f.runInTx(func(f txFileSystem) error {
		var err error
		res, err = f.Delete(r)
		return err
	})
	return res, err
}

func (f txFileSystem) Delete(r Resource) (Resource, error) {
	if !r.parentID.Valid {
		return Resource{}, ErrInsufficientPermissions
	}
	if r.deleted.Valid {
		return Resource{}, ErrResourceDeleted
	}
	parent, err := f.ResourceByID(r.parentID.Bytes)
	if err == nil {
		err = f.checkPermission(parent, PermissionWrite)
	}
	if err != nil {
		return Resource{}, err
	}

	if err := softDelete(f.db, r.id); err != nil {
		return Resource{}, err
	}
	if err := updateResourceModified(f.db, r.parentID.Bytes); err != nil {
		return Resource{}, err
	}

	r.deleted = pgtype.Timestamp{
		Valid: true,
		Time:  time.Now(),
	}
	return r, nil
}

func softDelete(db db.TxHandler, id uuid.UUID) error {
	n, q := selectResourceTree(id, false)
	r := goqu.T("resources")

	// Set modified and deleted
	query, params, _ := q.
		From(r).
		Where(r.Col("id").Eq(pg.From(n).Select("id"))).
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
}

func softDeleteChildren(db db.TxHandler, id, parent uuid.UUID) error {
	n, s := selectResourceTree(id, false)
	r := goqu.T("resources")

	// Mark deleted
	q, params, _ := s.
		From(r).
		Where(r.Col("id").Eq(pg.From(n).Select("id"))).
		Where(r.Col("id").Neq(id)).
		Update().
		Set(
			goqu.Record{
				"modified": goqu.L("NOW()"),
				"deleted":  goqu.L("NOW()"),
			}).
		ToSQL()
	if _, err := db.Exec(q, params...); err != nil {
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
	if _, err := db.Exec(q, args...); err != nil {
		return err
	}

	return updateResourceModified(db, parent)
}

func (f *FileSystem) DeleteForever(r Resource) error {
	return f.runInTx(func(f txFileSystem) error {
		return f.DeleteForever(r)
	})
}

func (f txFileSystem) DeleteForever(r Resource) error {
	if !r.parentID.Valid {
		return ErrInsufficientPermissions
	}
	parent, err := f.ResourceByID(r.parentID.Bytes)
	if err == nil {
		err = f.checkPermission(parent, PermissionWrite)
	}
	if err != nil {
		return err
	}
	// Select all descendants, including deleted resources
	n, q := selectResourceTree(r.id, true)

	if err := updateResourceModified(f.db, parent.id); err != nil {
		return err
		// deleteAllVersions needs to be called last, as it will enqueue the delete jobs
	} else if err := hardDeleteAllVersions(f.db, q, n); err != nil {
		return err
	}
	return nil
}

func collectDeletedVersions(rows pgx.Rows) ([]jobs.DeleteContentsArgs, error) {
	defer rows.Close()

	var result []jobs.DeleteContentsArgs
	var v jobs.DeleteContentsArgs
	var id uuid.UUID
	for rows.Next() {
		err := rows.Scan(&id, &v.Storage, &v.ImgRes)
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

func (f *FileSystem) RestoreDeleted(r Resource, parentPathOrUUID string, name string, autoRename bool) (res Resource, err error) {
	err = f.runInTx(func(f txFileSystem) error {
		var err error
		res, err = f.RestoreDeleted(r, parentPathOrUUID, name, autoRename)
		return err
	})
	return res, err
}

// RestoreDeleted restores a previously deleted resources
// Checks:
//   - Parent must not be deleted
//   - Parent must have write permission
//   - No name conflict with exiting resource
func (f txFileSystem) RestoreDeleted(r Resource, parentPathOrUUID string, name string, autoRename bool) (res Resource, err error) {
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

	if err = f.checkPermission(parent, PermissionWrite); err != nil {
		return
	}

	if name == "" {
		name = r.name
	}
	if name, err = detectNameConflict(f.db, parent.id, name, autoRename); err != nil {
		return
	}

	q, args, _ := pg.Delete(goqu.T("trash")).Where(goqu.C("id").Eq(r.id)).ToSQL()
	if _, err = f.db.Exec(q, args...); err != nil {
		return
	}

	if parent.id != r.parentID.Bytes || r.name != name {
		if err = updateResourceNameParent(f.db, r.id, name, pgtype.UUID{Bytes: parent.id, Valid: true}); err != nil {
			return
		} else {
			r.name = name
			r.parentID = pgtype.UUID{Bytes: parent.id, Valid: true}
			r.visibleParent = r.parentID
		}
	}
	n, s := selectResourceTree(r.id, false)
	tR := goqu.T("resources")
	query, params, _ := s.
		From(tR).
		Where(tR.Col("id").Eq(pg.From(n).Select("id"))).
		Update().Set(
		goqu.Record{
			"modified": goqu.L("NOW()"),
			"deleted":  nil,
		}).ToSQL()

	if _, err = f.db.Exec(query, params...); err != nil {
		return
	}

	if err = recomputePermissions(f.db, r.id); err != nil {
		return
	}

	r.deleted = pgtype.Timestamp{}
	res = r
	return
}
