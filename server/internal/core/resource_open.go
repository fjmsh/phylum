package core

import (
	"context"
	"encoding/hex"
	"hash"
	"io"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
)

func (f filesystem) OpenWrite(r Resource, versionID uuid.UUID) (io.WriteCloser, error) {
	if !r.hasPermission(PermissionWrite) {
		return nil, ErrInsufficientPermissions
	}
	if r.deleted.Valid {
		return nil, ErrResourceDeleted
	}
	if versionID == uuid.Nil {
		versionID, _ = uuid.NewV7()
	}
	if dest, err := storage.DefaultBackend().OpenWrite(versionID.String()); err != nil {
		return nil, err
	} else {
		return computeProps(dest, func(len int, hash hash.Hash, mimeType string) error {
			sum := hex.EncodeToString(hash.Sum(nil))
			err := f.runInTx(func(f filesystem) error {
				if err := f.createResourceVersion(r.id, versionID, int64(len), mimeType, sum); err != nil {
					return err
				}
				if err := f.updateResourceModified(r.id); err != nil {
					return err
				}
				return nil
			})
			if err != nil {
				return err
			}

			go moveVersionToTargetBackend(db.Get(context.Background()), versionID)
			return nil
		}), nil

	}
}

func (f filesystem) ReadDir(r Resource, recursive bool) ([]Resource, error) {
	return f.ReadDirDeleted(r, recursive, false)
}

func (f filesystem) ReadDirDeleted(r Resource, recursive, includeDeleted bool) ([]Resource, error) {
	if !r.hasPermission(PermissionRead) {
		return nil, ErrInsufficientPermissions
	}
	if !r.Dir() {
		return nil, ErrResourceNotCollection
	}

	var q *goqu.SelectDataset
	if !recursive {
		_, q = selectDirectChildren(r.id, r.deleted, includeDeleted)
	} else {
		_, _, q = selectResourceTree(r.id, true, includeDeleted, true)
	}

	query, args, _ := q.ToSQL()
	if rows, err := f.db.Query(query, args...); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, f.scanResourceWithoutParent)
	}
}

func (f filesystem) Walk(r Resource, depth int, fn func(Resource, string) error) error {
	suffix := ""
	if r.Dir() {
		suffix = "/"
	}
	err := fn(r, suffix)
	if err != nil {
		return err
	}
	if !r.Dir() || depth <= 0 {
		return nil
	}

	children, err := f.ReadDir(r, depth > 1)
	if err != nil {
		return err
	}

	// TODO: #Fix f.Walk
	for _, c := range children {
		if err := fn(c, suffix+c.Name()); err != nil {
			return err
		}
	}
	return nil
}
