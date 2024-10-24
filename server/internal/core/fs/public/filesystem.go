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
		f:             f,
		id:            r.ID,
		name:          r.Name,
		dir:           r.Dir,
		created:       r.Created.Time,
		modified:      r.Modified.Time,
		contentSize:   r.ContentSize,
		contentType:   r.ContentType,
		contentSHA256: r.ContentSha256,
	}, nil
}

func (f filesystem) OpenRead(r Resource, start, length int64) (io.ReadCloser, error) {
	return f.cs.OpenRead(r.id, start, length)
}

func (f filesystem) ReadDir(r Resource, recursive bool) ([]Resource, error) {
	if !r.dir {
		return nil, fs.ErrResourceNotCollection
	}
	children, err := f.db.ReadDir(f.ctx, db.ReadDirParams{
		ID:          r.id,
		IncludeRoot: false,
		Recursive:   recursive,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Resource, len(children))

	for i, c := range children {
		result[i] = Resource{
			f:             f,
			id:            c.ID,
			name:          c.Name,
			dir:           c.Dir,
			created:       c.Created.Time,
			modified:      c.Modified.Time,
			contentSize:   c.ContentSize,
			contentType:   c.ContentType,
			contentSHA256: c.ContentSha256,
		}
	}
	return result, nil
}
