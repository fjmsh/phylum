package public

import (
	"context"
	"io"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type FileSystem interface {
	ResourceByPath(path string) (Resource, error)
	OpenRead(r Resource, start, length int64) (io.ReadCloser, error)
	ReadDir(r Resource, recursive bool) ([]Resource, error)
}

type filesystem struct {
	ctx    context.Context
	db     *db.DbHandler
	cs     storage.Storage
	rootID uuid.UUID
}

func (f filesystem) ResourceByPath(path string) (Resource, error) {
	r, err := f.db.ResourceByPath(f.ctx, db.ResourceByPathParams{Root: f.rootID, Path: path})
	if err == pgx.ErrNoRows || !r.Found {
		err = fs.ErrResourceNotFound
	}
	if err != nil {
		return Resource{}, err
	}

	return Resource{
		ID:            r.ID,
		Name:          r.Name,
		Dir:           r.Dir,
		Created:       r.Created.Time,
		Modified:      r.Modified.Time,
		ContentSize:   r.ContentSize,
		ContentSHA256: r.ContentSha256,
	}, nil
}

func (f filesystem) OpenRead(r Resource, start, length int64) (io.ReadCloser, error) {
	return f.cs.OpenRead(r.ID, start, length)
}

func (f filesystem) ReadDir(r Resource, recursive bool) ([]Resource, error) {
	if !r.Dir {
		return nil, fs.ErrResourceNotCollection
	}
	children, err := f.db.ReadDir(f.ctx, db.ReadDirParams{
		ID:          r.ID,
		IncludeRoot: false,
		Recursive:   recursive,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Resource, len(children))

	for i, c := range children {
		result[i] = Resource{
			ID:            c.ID,
			Name:          c.Name,
			Created:       c.Created.Time,
			Modified:      c.Modified.Time,
			Deleted:       nil, // Query will not return deleted results
			Dir:           c.Dir,
			ContentSize:   c.ContentSize,
			ContentSHA256: c.ContentSha256,
		}
	}
	return result, nil
}
