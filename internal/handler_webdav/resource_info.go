package webdav

import (
	"context"
	"errors"
	"fmt"
	"io"
	"mime"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/library"
	"github.com/shroff/phylum/server/internal/webdav"
)

type resourceInfo struct {
	lib        *library.Library
	name       string
	size       int64
	collection bool
	modTime    time.Time
	resourceID uuid.UUID
	etag       string
}

func (ri resourceInfo) Name() string       { return ri.name }
func (ri resourceInfo) Size() int64        { return ri.size }
func (ri resourceInfo) ModTime() time.Time { return ri.modTime }
func (ri resourceInfo) IsDir() bool        { return ri.collection }
func (ri resourceInfo) ETag() string {
	if ri.etag != "" {
		return ri.etag
	}
	// The Apache http 2.4 web server by default concatenates the
	// modification time and size of a file.
	return fmt.Sprintf(`"%x%x"`, ri.modTime.UnixMilli(), ri.size)
}
func (ri resourceInfo) ContentType() string {
	mimeType := mime.TypeByExtension(filepath.Ext(ri.name))
	if mimeType != "" {
		return mimeType
	}
	return "application/octet-stream"
}
func (ri resourceInfo) OpenRead(ctx context.Context) (io.ReadSeekCloser, error) {
	return ri.lib.Open(ctx, ri.resourceID, false)
}
func (ri resourceInfo) Readdir(ctx context.Context) ([]webdav.ResourceInfo, error) {
	if !ri.collection {
		return nil, errors.New("readdir not supported for non-collection resources")
	}

	children, err := ri.lib.ReadDir(context.Background(), ri.resourceID, false, false)
	if err != nil {
		return nil, err
	}

	result := make([]webdav.ResourceInfo, len(children))
	for i, c := range children {
		result[i] = resourceInfo{
			lib:        ri.lib,
			name:       c.Name,
			size:       int64(c.Size.Int32),
			modTime:    c.Modified.Time,
			collection: c.Dir,
			resourceID: c.ID,
			etag:       c.Etag.String,
		}
	}
	return result, nil

}
