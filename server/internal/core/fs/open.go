package fs

import (
	"crypto/sha256"
	"io"

	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) OpenRead(sr serve.Resource, start, length int64) (io.ReadCloser, error) {
	r, ok := sr.(Resource)
	if !ok {
		return nil, ErrUnexpectedType
	}
	if !r.hasPermission(PermissionRead) {
		return nil, ErrInsufficientPermissions
	}
	return f.cs.OpenRead(r.ID, start, length)
}

func (f filesystem) OpenWrite(r Resource) (io.WriteCloser, error) {
	if !r.hasPermission(PermissionWrite) {
		return nil, ErrInsufficientPermissions
	}
	return f.cs.OpenWrite(r.ID, sha256.New, func(len int, sum, mime string) error {
		return f.db.UpdateResourceContents(f.ctx, db.UpdateResourceContentsParams{
			ID:            r.ID,
			ContentType:   mime,
			ContentSize:   int64(len),
			ContentSha256: sum,
		})
	})
}

func (f filesystem) ReadDir(sr serve.Resource, recursive bool) ([]serve.Resource, error) {
	r, ok := sr.(Resource)
	if !ok {
		return nil, ErrUnexpectedType
	}
	if !r.hasPermission(PermissionRead) {
		return nil, ErrInsufficientPermissions
	}
	if !r.Dir {
		return nil, ErrResourceNotCollection
	}
	children, err := f.db.ReadDir(f.ctx, db.ReadDirParams{
		ID:          r.ID,
		IncludeRoot: false,
		Recursive:   recursive,
	})
	if err != nil {
		return nil, err
	}

	result := make([]serve.Resource, len(children))

	for i, c := range children {
		path := r.Path + c.Path
		if r.Path == "/" {
			path = c.Path
		}
		result[i] = Resource{
			ID:            c.ID,
			ParentID:      c.Parent,
			Name:          c.Name,
			Created:       c.Created.Time,
			Modified:      c.Modified.Time,
			Deleted:       nil, // Query will not return deleted results
			Dir:           c.Dir,
			ContentSize:   c.ContentSize,
			ContentType:   c.ContentType,
			ContentSHA256: c.ContentSha256,
			Permissions:   string(c.Permissions),
			Path:          path,
			// Not Needed
			// UserPermissions: 0,
			// InheritedPermissions: "",
		}
	}
	return result, nil
}

func (f filesystem) ProcessResources(r serve.Resource, depth int, fn func(serve.Resource) error) error {
	err := fn(r)
	if err != nil {
		return err
	}
	if !r.FSDir() || depth <= 0 {
		return nil
	}

	children, err := f.ReadDir(r, depth > 1)
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
