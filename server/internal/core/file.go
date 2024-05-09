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

type FileInfo interface {
	ID() uuid.UUID
	Name() string
	Size() int64
	ModTime() time.Time
	IsDir() bool
	ETag() string
	ContentType() string
}

type File interface {
	FileInfo
	OpenRead(ctx context.Context, start, length int64) (io.ReadCloser, error)
	ReadDir(ctx context.Context) ([]FileInfo, error)
}

type fileInfo struct {
	id         uuid.UUID
	name       string
	size       int64
	collection bool
	modTime    time.Time
	etag       string
}

type file struct {
	fileInfo
	silo *Silo
}

func (f fileInfo) ID() uuid.UUID { return f.id }

func (f fileInfo) Name() string { return f.name }

func (f fileInfo) Size() int64 { return f.size }

func (f fileInfo) ModTime() time.Time { return f.modTime }

func (f fileInfo) IsDir() bool { return f.collection }

func (f fileInfo) ETag() string {
	if f.etag != "" {
		return f.etag
	}
	// The Apache http 2.4 web server by default concatenates the
	// modification time and size of a file.
	return fmt.Sprintf(`"%x%x"`, f.modTime.UnixMilli(), f.size)
}

func (f fileInfo) ContentType() string {
	mimeType := mime.TypeByExtension(filepath.Ext(f.name))
	if mimeType != "" {
		return mimeType
	}
	return "application/octet-stream"
}

func (f file) OpenRead(ctx context.Context, start, length int64) (io.ReadCloser, error) {
	return f.silo.OpenRead(ctx, f.id, start, length)
}

func (f file) ReadDir(ctx context.Context) ([]FileInfo, error) {
	return f.silo.ReadDir(ctx, f.id, false, false)
}
