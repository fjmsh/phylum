package publink

import (
	"errors"
	"io"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/db"
)

type Resource struct {
	f             filesystem
	id            uuid.UUID
	name          string
	dir           bool
	path          string
	created       time.Time
	modified      time.Time
	contentSize   int64
	contentType   string
	contentSHA256 string
}

func (r Resource) FSID() uuid.UUID         { return r.id }
func (r Resource) FSName() string          { return r.name }
func (r Resource) FSPath() string          { return r.path }
func (r Resource) FSDir() bool             { return r.dir }
func (r Resource) FSCreated() time.Time    { return r.created }
func (r Resource) FSModified() time.Time   { return r.modified }
func (r Resource) FSContentSize() int64    { return r.contentSize }
func (r Resource) FSContentSHA256() string { return r.contentSHA256 }
func (r Resource) FSContentType() string   { return r.contentType }

func (r Resource) OpenRead(start, length int64) (io.ReadCloser, error) {
	return r.f.cs.OpenRead(r.id, start, length)
}

func (r Resource) ReadDir(recursive bool) ([]serve.Resource, error) {
	if !r.dir {
		return nil, errors.New("resource is not a collection")
	}
	children, err := r.f.db.ReadDir(r.f.ctx, db.ReadDirParams{
		ID:          r.id,
		IncludeRoot: false,
		Recursive:   recursive,
	})
	if err != nil {
		return nil, err
	}

	result := make([]serve.Resource, len(children))

	for i, c := range children {
		path := r.path + c.Path
		if r.path == "/" {
			path = c.Path
		}
		result[i] = Resource{
			f:             r.f,
			id:            c.ID,
			name:          c.Name,
			dir:           c.Dir,
			path:          path,
			created:       c.Created.Time,
			modified:      c.Modified.Time,
			contentSize:   c.ContentSize,
			contentType:   c.ContentType,
			contentSHA256: c.ContentSha256,
		}
	}
	return result, nil
}
