package fs

import (
	"crypto/sha256"
	"io"

	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) OpenRead(r Resource, start, length int64) (io.ReadCloser, error) {
	if r.UserPermissions < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	return f.cs.OpenRead(r.ID, start, length)
}

func (f filesystem) OpenWrite(r Resource) (io.WriteCloser, error) {
	if r.UserPermissions < PermissionReadWrite {
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

func (f filesystem) ReadDir(r Resource) ([]Resource, error) {
	if r.UserPermissions < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	if !r.Dir {
		return nil, ErrResourceNotCollection
	}
	children, err := f.db.ReadDir(f.ctx, db.ReadDirParams{
		ID:          r.ID,
		IncludeRoot: false,
		Recursive:   false,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Resource, len(children))
	for i, c := range children {
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
			// Not Needed
			// UserPermissions: 0,
			// InheritedPermissions: "",
		}
	}
	return result, nil
}
