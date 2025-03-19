package fs

import (
	"context"
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"path"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

func (f filesystem) TrashList(cursor string, n int) ([]Resource, string, error) {
	var username pgtype.Text
	if !f.fullAccess {
		username.String = f.username
		username.Valid = true
	}

	var lastTimestamp pgtype.Timestamp
	var lastID uuid.UUID
	if cursor != "" {
		if d, err := base64.StdEncoding.DecodeString(cursor); err != nil {
			return nil, "", err
		} else if len(d) != 24 {
			return nil, "", fmt.Errorf("illegal cursor. Length %d not expected", len(d))
		} else {
			lastID, _ = uuid.FromBytes(d[:16])
			t := int64(binary.LittleEndian.Uint64(d[16:]))
			lastTimestamp.Time = time.Unix(t/1e9, t%1e9).UTC()
			lastTimestamp.Valid = true
		}
	}

	if res, err := f.db.TrashList(f.ctx, db.TrashListParams{
		Username:      username,
		N:             int32(n),
		LastTimestamp: lastTimestamp,
		LastID:        lastID,
	}); err != nil {
		return nil, "", err
	} else {
		if res == nil {
			return nil, "", nil
		}
		deleted := make([]Resource, len(res))
		for i, r := range res {
			deleted[i] = ResourceFromDB(r)
		}
		last := deleted[len(deleted)-1]
		c := make([]byte, 24)

		b, _ := last.id.MarshalBinary()
		copy(c, b)

		binary.LittleEndian.PutUint64(c[16:], uint64(last.deleted.UnixNano()))
		return deleted, base64.StdEncoding.EncodeToString(c), nil
	}
}

func (f filesystem) TrashSummary() (int, int, error) {
	var username pgtype.Text
	if !f.fullAccess {
		username.String = f.username
		username.Valid = true
	}
	if res, err := f.db.TrashSummary(f.ctx, username); err != nil {
		return 0, 0, err
	} else {
		return int(res.Items), int(res.Size), nil
	}
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
		if del, err := f.db.RestoreDeleted(f.ctx, db.RestoreDeletedParams{Username: username, ResourceID: r.id}); err != nil {
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

func HardDeleteExpired(ctx context.Context, t time.Time) (int, error) {
	d := db.Get()
	rows, err := d.HardDeleteExpired(ctx, pgtype.Timestamp{Valid: true, Time: t.UTC()})
	ids := make([]uuid.UUID, len(rows))
	for _, d := range rows {
		if !d.Dir {
			ids = append(ids, d.ID)
		}
	}
	storage.Get().DeleteAll(ids)
	return len(rows), err
}

func (f filesystem) TrashEmpty() (int, error) {
	var username pgtype.Text
	if !f.fullAccess {
		username.String = f.username
		username.Valid = true
	}
	d := db.Get()
	rows, err := d.EmptyTrash(f.ctx, username)
	ids := make([]uuid.UUID, len(rows))
	for _, d := range rows {
		if !d.Dir {
			ids = append(ids, d.ID)
		}
	}
	storage.Get().DeleteAll(ids)
	return len(rows), err
}
