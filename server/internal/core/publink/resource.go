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
	created       time.Time
	modified      time.Time
	contentLength int64
	contentType   string
	contentSHA256 string
}

func (r Resource) FSID() uuid.UUID       { return r.id }
func (r Resource) Name() string          { return r.name }
func (r Resource) Dir() bool             { return r.dir }
func (r Resource) Created() time.Time    { return r.created }
func (r Resource) Modified() time.Time   { return r.modified }
func (r Resource) ContentLength() int64  { return r.contentLength }
func (r Resource) ContentSHA256() string { return r.contentSHA256 }
func (r Resource) ContentType() string   { return r.contentType }

func (r Resource) OpenRead(start, length int64) (io.ReadCloser, error) {
	return r.f.cs.OpenRead(r.id, start, length)
}

func (r Resource) ReadDir(recursive bool) ([]serve.Resource, error) {
	if !r.dir {
		return nil, errors.New("resource is not a collection")
	}
	if recursive {
		return nil, errors.New("cannot read directory recursively")
	}
	children, err := r.f.db.ReadDir(r.f.ctx, db.ReadDirParams{
		ResourceID: r.id,
		MinDepth:   1,
		MaxDepth:   1,
	})
	if err != nil {
		return nil, err
	}

	result := make([]serve.Resource, len(children))

	for i, c := range children {
		result[i] = Resource{
			f:             r.f,
			id:            c.ID,
			name:          c.Name,
			dir:           c.Dir,
			created:       c.Created.Time,
			modified:      c.Modified.Time,
			contentLength: c.ContentLength,
			contentType:   c.ContentType,
			contentSHA256: c.ContentSha256,
		}
	}
	return result, nil
}
