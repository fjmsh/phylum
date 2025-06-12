package core

import (
	"encoding/hex"
	"hash"
	"io"

	"codeberg.org/shroff/phylum/server/internal/jobs"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// TODO: #tx Change to Write(Resource, uuid.UUID, func(io.WriteCloser) error) error
func (f fileSystem) OpenWrite(r Resource, versionID uuid.UUID) (io.WriteCloser, error) {
	// TODO: #implement
	return nil, nil
}

func (f txFileSystem) OpenWrite(r Resource, versionID uuid.UUID) (io.WriteCloser, error) {
	if err := r.checkPermission(f.user, PermissionWrite); err != nil {
		return nil, err
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
			if err := createResourceVersion(f.db, r.id, versionID, int64(len), mimeType, sum); err != nil {
				return err
			}
			if err := updateResourceModified(f.db, r.id); err != nil {
				return err
			}

			// TODO: #tx pass in transaction
			return jobs.MigrateVersionContents(versionID)
		}), nil

	}
}

func (f fileSystem) ReadDir(r Resource, recursive bool) ([]Resource, error) {
	return f.ReadDirDeleted(r, recursive, false)
}

func (f fileSystem) ReadDirDeleted(r Resource, recursive, includeDeleted bool) ([]Resource, error) {
	if !r.Dir() {
		return nil, ErrResourceNotCollection
	}

	var q *goqu.SelectDataset
	if !recursive {
		_, q = selectDirectChildren(r.id, r.deleted, includeDeleted)
	} else {
		n, qq := selectResourceTree(r.id, includeDeleted)
		id := r.id
		var r exp.AliasedExpression
		q, r = selectResources(qq, n)
		q = q.Where(r.Col("id").Neq(id))
	}

	query, args, _ := q.ToSQL()
	if rows, err := f.db.Query(query, args...); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanResourceWithoutParent)
	}
}

func (f fileSystem) Walk(r Resource, depth int, fn func(Resource, string) error) error {
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
