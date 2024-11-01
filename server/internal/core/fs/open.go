package fs

import (
	"crypto/sha256"
	"io"

	"github.com/google/uuid"
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
			ContentSize:   int64(len),
			ContentSha256: sum,
		})
	})
}

func (r Resource) ReadDir(recursive bool) ([]serve.ResourceInfo, error) {
	if !r.hasPermission(PermissionRead) {
		return nil, ErrInsufficientPermissions
	}
	if !r.FSDir() {
		return nil, ErrResourceNotCollection
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

	result := make([]serve.ResourceInfo, len(children))
	path := make(map[uuid.UUID]string)
	path[r.ID()] = r.FSPath()
	if r.FSPath() == "/" {
		path[r.ID()] = ""
	}
	for i, c := range children {
		info := resourceInfoFromDBPublinkedResource(c)
		info.Path = path[*info.ParentID] + "/" + info.Name
		path[info.ID] = info.Path
		result[i] = info
	}
	return result, nil
}

func (r Resource) Walk(depth int, fn func(serve.ResourceInfo) error) error {
	err := fn(r)
	if err != nil {
		return err
	}
	if !r.FSDir() || depth <= 0 {
		return nil
	}

	children, err := r.ReadDir(depth > 1)
	if err != nil {
		return err
	}

	for _, c := range children {
		if err := fn(c); err != nil {
			return err
		}
	}
	return nil
}
