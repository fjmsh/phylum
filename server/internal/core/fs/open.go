package fs

import (
	"crypto/sha256"
	"io"

	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (r Resource) OpenRead(start, length int64) (io.ReadCloser, error) {
	if !r.hasPermission(PermissionRead) {
		return nil, ErrInsufficientPermissions
	}
	return r.f.cs.OpenRead(r.ID, start, length)
}

func (r Resource) OpenWrite() (io.WriteCloser, error) {
	if !r.hasPermission(PermissionWrite) {
		return nil, ErrInsufficientPermissions
	}
	return r.f.cs.OpenWrite(r.ID, sha256.New, func(len int, sum, mime string) error {
		return r.f.db.UpdateResourceContents(r.f.ctx, db.UpdateResourceContentsParams{
			ID:            r.ID,
			ContentType:   mime,
			ContentSize:   int64(len),
			ContentSha256: sum,
		})
	})
}

func (r Resource) ReadDir(recursive bool) ([]serve.Resource, error) {
	if !r.hasPermission(PermissionRead) {
		return nil, ErrInsufficientPermissions
	}
	if !r.Dir {
		return nil, ErrResourceNotCollection
	}
	children, err := r.f.db.ReadDir(r.f.ctx, db.ReadDirParams{
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
			f:               r.f,
			ID:              c.ID,
			ParentID:        c.Parent,
			Name:            c.Name,
			Created:         c.Created.Time,
			Modified:        c.Modified.Time,
			Deleted:         nil, // Query will not return deleted results
			Dir:             c.Dir,
			ContentSize:     c.ContentSize,
			ContentType:     c.ContentType,
			ContentSHA256:   c.ContentSha256,
			Permissions:     string(c.Permissions),
			Publinks:        int(r.Publinks),
			Path:            path,
			UserPermissions: r.UserPermissions,
			// Not Needed
			// InheritedPermissions: "",
		}
	}
	return result, nil
}

func (r Resource) Walk(depth int, fn func(serve.Resource) error) error {
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
