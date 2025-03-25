package fs

import (
	"crypto/sha256"
	"io"

	"github.com/doug-martin/goqu/v9"
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

	var q *goqu.SelectDataset
	if !recursive {
		_, q = selectDirectChildren(r.id, r.deleted)
	} else {
		t := goqu.T("resources").As("r")
		n, qq := selectResourceTree(r.id, true, false)
		q = qq.
			From(t).Join(n, goqu.On(t.Col("id").Eq(n.Col("id")))).
			Select(t.All())
	}

	query, args, _ := q.ToSQL()
	if rows, err := r.f.db.Query(r.f.ctx, query, args...); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, r.f.scanServeResource)
	}
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
