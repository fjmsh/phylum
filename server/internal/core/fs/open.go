package fs

import (
	"encoding/hex"
	"errors"
	"hash"
	"io"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/storage"
)

func (r Resource) OpenRead(start, length int, versionID uuid.UUID) (io.ReadCloser, error) {
	if versionID != uuid.Nil {
		// TODO: #backend
		return r.f.openRead("", versionID, start, length)
	}
	if version, err := r.LatestVersion(); err != nil {
		return nil, err
	} else {
		// TODO: #backend
		return r.f.openRead("", version.ID, start, length)
	}
}

func (f filesystem) openRead(backend string, versionID uuid.UUID, start, length int) (io.ReadCloser, error) {
	if b := storage.GetBackend(backend); b == nil {
		return nil, errors.New("storage backend not found: " + backend)
	} else {
		return b.OpenRead(versionID, start, length)
	}
}

func (r Resource) OpenWrite(versionID uuid.UUID) (io.WriteCloser, error) {
	if !r.hasPermission(PermissionWrite) {
		return nil, ErrInsufficientPermissions
	}
	if r.deleted.Valid {
		return nil, ErrResourceDeleted
	}
	if versionID == uuid.Nil {
		versionID, _ = uuid.NewV7()
	}
	if dest, err := storage.DefaultBackend().OpenWrite(versionID); err != nil {
		return nil, err
	} else {
		return computeProps(dest, func(len int, hash hash.Hash, mimeType string) error {
			sum := hex.EncodeToString(hash.Sum(nil))
			return r.f.runInTx(func(f filesystem) error {
				if err := f.createResourceVersion(r.id, versionID, int64(len), mimeType, sum); err != nil {
					return err
				}
				return f.updateResourceModified(r.id)
			})
		}), nil
	}
}

func (r Resource) ReadDir(recursive bool) ([]Resource, error) {
	return r.ReadDirDeleted(recursive, false)
}

func (r Resource) ReadDirDeleted(recursive, includeDeleted bool) ([]Resource, error) {
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
	if rows, err := r.f.db.Query(query, args...); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, r.f.scanResourceWithoutParent)
	}
}

func (r Resource) Walk(depth int, fn func(Resource, string) error) error {
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

	children, err := r.ReadDir(depth > 1)
	if err != nil {
		return err
	}

	for _, c := range children {
		if err := fn(c, suffix+c.Name()); err != nil {
			return err
		}
	}
	return nil
}
