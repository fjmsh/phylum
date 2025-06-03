package fs

import (
	"crypto/sha256"
	"io"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (r Resource) OpenRead(start, length int, versionID uuid.UUID) (io.ReadCloser, error) {
	if versionID != uuid.Nil {
		return r.f.cs.OpenRead(versionID, start, length)
	}
	if version, err := r.LatestVersion(); err != nil {
		return nil, err
	} else {
		return r.f.cs.OpenRead(version.ID, start, length)
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
	return r.f.cs.OpenWrite(versionID, sha256.New, func(len int, sum, mime string) error {
		return r.f.runInTx(func(f filesystem) error {
			if err := f.createResourceVersion(r.id, versionID, int64(len), mime, sum); err != nil {
				return err
			}
			return f.updateResourceModified(r.id)
		})
	})
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
