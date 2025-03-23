package fs

import (
	"context"
	"fmt"
	"path"
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
)

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
