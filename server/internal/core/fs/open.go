package fs

import (
	"crypto/sha256"
	"io"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (r Resource) OpenRead(start, length int64) (io.ReadCloser, error) {
	if !r.hasPermission(PermissionRead) {
		return nil, ErrInsufficientPermissions
	}
	return r.f.cs.OpenRead(r.ID(), start, length)
}

func (r Resource) OpenWrite() (io.WriteCloser, error) {
	if !r.hasPermission(PermissionWrite) {
		return nil, ErrInsufficientPermissions
	}
	return r.f.cs.OpenWrite(r.ID(), sha256.New, func(len int, sum, mime string) error {
		return r.f.db.UpdateResourceContents(r.f.ctx, db.UpdateResourceContentsParams{
			ID:            r.ID(),
			ContentType:   mime,
			ContentLength: int64(len),
			ContentSha256: sum,
		})
	})
}

func (r Resource) ReadDir(recursive bool) ([]serve.Resource, error) {
	if !r.hasPermission(PermissionRead) {
		return nil, ErrInsufficientPermissions
	}
	if !r.Dir() {
		return nil, ErrResourceNotCollection
	}

	if !recursive {
		_, q := selectDirectChildren(r.id, r.deleted)
		query, args, _ := q.ToSQL()
		if rows, err := r.f.db.Query(r.f.ctx, query, args...); err != nil {
			return nil, err
		} else {
			return pgx.CollectRows(rows, r.f.scanServeResource)
		}
	}
	maxDepth := 1
	if recursive {
		maxDepth = 1000
	}
	children, err := r.f.db.ReadDir(r.f.ctx, db.ReadDirParams{
		ResourceID: r.ID(),
		MinDepth:   1,
		MaxDepth:   int32(maxDepth),
	})
	if err != nil {
		return nil, err
	}

	result := make([]serve.Resource, len(children))
	for i, c := range children {
		info := ResourceFromDB(c)
		result[i] = info
	}
	return result, nil
}

func (r Resource) Walk(depth int, fn func(serve.ResourceInfo, string) error) error {
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
