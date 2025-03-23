package fs

import (
	"context"
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"path"
	"strings"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/sirupsen/logrus"
)

const trashDuration = 30 * 24 * time.Hour

func (f filesystem) TrashList(cursor string, n uint) ([]Resource, string, error) {
	var username pgtype.Text
	if !f.fullAccess {
		username.String = f.username
		username.Valid = true
	}

	q := pg.From("resources").
		Where(goqu.C("deleted").IsNotNull())
	if !f.fullAccess {
		q = q.Where(goqu.L("permissions[?]::INTEGER <> 0", f.username))
	}
	if cursor != "" {
		if d, err := base64.StdEncoding.DecodeString(cursor); err != nil {
			return nil, "", err
		} else if len(d) != 24 {
			return nil, "", fmt.Errorf("illegal cursor. Length %d not expected", len(d))
		} else {
			t := int64(binary.LittleEndian.Uint64(d[16:]))
			lastID, _ := uuid.FromBytes(d[:16])
			lastTimestamp := time.Unix(t/1e9, t%1e9).UTC()
			q = q.Where(
				goqu.Or(
					goqu.I("deleted").Lt(goqu.V(lastTimestamp)),
					goqu.And(
						goqu.I("deleted").Eq(goqu.V(lastTimestamp)),
						goqu.I("id").Lt(goqu.V(lastID)),
					)))
		}
	}

	query, params, _ := q.
		Order(goqu.C("deleted").Desc()).
		OrderAppend(goqu.C("id").Desc()).
		Limit(n).
		ToSQL()

	if rows, err := f.db.Query(f.ctx, query, params...); err != nil {
		return nil, "", err
	} else if res, err := pgx.CollectRows(rows, scanResourceRow); err != nil {
		return nil, "", err
	} else {
		if res == nil {
			return nil, "", nil
		}
		last := res[len(res)-1]
		c := make([]byte, 24)

		b, _ := last.id.MarshalBinary()
		copy(c, b)

		binary.LittleEndian.PutUint64(c[16:], uint64(last.deleted.UnixNano()))
		return res, base64.StdEncoding.EncodeToString(c), nil
	}
}

func scanResourceRow(row pgx.CollectableRow) (Resource, error) {
	var r Resource
	err := row.Scan(
		&r.id,
		&r.name,
		&r.parentID,
		&r.dir,
		&r.created,
		&r.modified,
		&r.deleted,
		&r.contentLength,
		&r.contentType,
		&r.contentSHA256,
		&r.permissions,
		&r.grants,
	)
	return r, err
}

// RestoreDeleted restores a previously deleted resources
// Checks:
//   - Parent must not be deleted
//   - Parent must have write permission
//   - No name conflict with exiting resource
func (r Resource) Restore(parentPathOrUUID string, name string, autoRename bool) (res Resource, count int, size int64, err error) {
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
	_, err = r.f.db.ChildResourceByName(r.f.ctx, db.ChildResourceByNameParams{Parent: p.id, Name: name})
	if autoRename && err == nil {
		ext := path.Ext(name)
		basename := name[:len(name)-len(ext)]
		counter := 1
		for {
			name = fmt.Sprintf("%s (%d)%s", basename, counter, ext)
			if _, err = r.f.db.ChildResourceByName(r.f.ctx, db.ChildResourceByNameParams{Parent: p.id, Name: name}); err == nil {
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

	var username pgtype.Text
	if !r.f.fullAccess {
		username.String = r.f.username
		username.Valid = true
	}
	err = r.f.db.WithTx(r.f.ctx, func(dbh *db.DbHandler) error {
		f := r.f.withDb(dbh)
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

func (f filesystem) markNotDeleted(ctx context.Context, id uuid.UUID) ([]int64, error) {
	table := goqu.T("resources").As("r")
	nodes := goqu.T("nodes")
	q := selectResourceTree(pg.From(table), nodes, id, false).
		Where(table.Col("id").Eq(pg.Select("id").From(nodes))).
		Update().Set(
		goqu.Record{
			"modified": goqu.L("NOW()"),
			"deleted":  nil,
		}).
		Returning(table.Col("content_length"))

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

func SetupTrashCompactor() {
	ticker := time.NewTimer(24 * time.Hour)
	go func() {
		for {
			<-ticker.C
			TrashCompact()
		}
	}()
	TrashCompact()
}

func TrashCompact() {
	t := time.Now().Add(-trashDuration)
	if d, err := trashCompact(t); err != nil {
		logrus.Error(err)
	} else {
		logrus.Info(fmt.Sprintf("Removed %d files deleted before %s", d, t.Format(time.RFC1123)))
	}
}

func trashCompact(t time.Time) (int, error) {
	q := pg.
		From("resources").
		Where(goqu.C("deleted").Lt(goqu.V(t.UTC()))).
		Delete().
		Returning("id", "dir")
	query, args, _ := q.ToSQL()
	count, ids, err := collectDeletedRows(db.Get().Query(context.Background(), query, args...))
	if err != nil {
		return 0, err
	}
	errors := storage.Get().DeleteAll(ids)
	for _, err := range errors {
		logrus.Warn(err)
	}
	return count, err
}

func (f filesystem) TrashSummary() (int, int, error) {
	q := f.selectDeletedResources().
		Select(
			goqu.COALESCE(goqu.SUM("content_length"), 0),
			goqu.COUNT("*"))

	query, args, _ := q.ToSQL()
	row := f.db.QueryRow(f.ctx, query, args...)
	var size int
	var items int
	err := row.Scan(&size, &items)
	return items, size, err
}

func (f filesystem) TrashEmpty() (int, error) {
	q := f.selectDeletedResources().
		Delete().
		Returning("id", "dir")
	query, args, _ := q.ToSQL()
	count, ids, err := collectDeletedRows(f.db.Query(f.ctx, query, args...))
	storage.Get().DeleteAll(ids)
	return count, err
}

func (f filesystem) selectDeletedResources() *goqu.SelectDataset {
	q := pg.
		From("resources").
		Where(goqu.C("deleted").IsNotNull())
	if !f.fullAccess {
		q = q.Where(goqu.L("permissions[?]::INTEGER <> 0", f.username))
	}
	return q
}

func collectDeletedRows(rows pgx.Rows, e error) (count int, ids []uuid.UUID, err error) {
	if e != nil {
		return 0, nil, e
	}
	defer rows.Close()
	var id uuid.UUID
	var dir bool
	for rows.Next() {
		if err := rows.Scan(&id, &dir); err != nil {
			return count, nil, err
		}
		if !dir {
			ids = append(ids, id)
		}
		count++
	}
	err = rows.Err()
	return count, ids, err
}
