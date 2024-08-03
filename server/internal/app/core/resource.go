package core

import (
	"context"
	"fmt"
	"io"
	"mime"
	"path/filepath"
	"time"

	"github.com/google/uuid"
)

type ResourceInfo interface {
	ID() uuid.UUID
	Name() string
	Size() int64
	ModTime() time.Time
	IsDir() bool
	ETag() string
	ContentType() string
}

type Resource interface {
	ResourceInfo
	OpenRead(ctx context.Context, start, length int64) (io.ReadCloser, error)
	ReadDir(ctx context.Context) ([]Resource, error)
}

type resource struct {
	silo       Silo
	id         uuid.UUID
	parentID   *uuid.UUID
	name       string
	size       int64
	collection bool
	modTime    time.Time
	etag       string
}

func (r resource) ID() uuid.UUID { return r.id }

func (r resource) ParentID() *uuid.UUID { return r.parentID }

func (r resource) Name() string { return r.name }

func (r resource) Size() int64 { return r.size }

func (r resource) ModTime() time.Time { return r.modTime }

func (r resource) IsDir() bool { return r.collection }

func (r resource) ETag() string {
	if r.etag != "" {
		return r.etag
	}
	// The Apache http 2.4 web server by default concatenates the
	// modification time and size of a file.
	return fmt.Sprintf(`"%x%x"`, r.modTime.UnixMilli(), r.size)
}

func (r resource) ContentType() string {
	mimeType := mime.TypeByExtension(filepath.Ext(r.name))
	if mimeType != "" {
		return mimeType
	}
	return "application/octet-stream"
}

func (f resource) OpenRead(ctx context.Context, start, length int64) (io.ReadCloser, error) {
	return f.silo.OpenRead(ctx, f.id, start, length)
}

func (f resource) ReadDir(ctx context.Context) ([]Resource, error) {
	return f.silo.ReadDir(ctx, f.id, false, false)
}
