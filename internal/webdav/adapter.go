package webdav

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"os"
	"strings"

	webdav "github.com/emersion/go-webdav"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/library"
	"github.com/shroff/phylum/server/internal/sql"
)

type adapter struct {
	lib    *library.Library
	prefix string
}

func (a adapter) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	resource, err := a.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	return a.lib.Open(resource.ID, os.O_RDONLY)
}

func (a adapter) Stat(ctx context.Context, name string) (*webdav.FileInfo, error) {
	resource, err := a.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	val := &webdav.FileInfo{
		Path:     string(a.prefix + resource.Path),
		Size:     int64(resource.Size.Int32),
		ModTime:  resource.Modified.Time,
		IsDir:    resource.Dir,
		MIMEType: resource.Name,
		ETag:     resource.Etag.String,
	}
	return val, nil
}
func (a adapter) ReadDir(ctx context.Context, name string, recursive bool) ([]webdav.FileInfo, error) {
	dir, err := a.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	if !dir.Dir {
		return nil, fs.ErrInvalid
	}
	children, err := a.lib.ReadDir(ctx, dir.ID, false, recursive)
	if err != nil {
		return nil, err
	}

	result := make([]webdav.FileInfo, len(children))
	prefix := a.prefix + dir.Path
	for i, c := range children {
		result[i] = webdav.FileInfo{
			Path:     string(prefix + c.Path),
			Size:     int64(c.Size.Int32),
			ModTime:  c.Modified.Time,
			IsDir:    c.Dir,
			MIMEType: c.Name,
			ETag:     c.Etag.String,
		}
	}
	return result, nil
}
func (a adapter) Create(ctx context.Context, name string) (io.WriteCloser, error) {
	var id uuid.UUID
	if resource, err := a.resourceByPath(ctx, name); err == nil {
		id = resource.ID
	} else {
		name = strings.TrimRight(name, "/")
		index := strings.LastIndex(name, "/")
		parentPath := name[0:index]
		parent, err := a.resourceByPath(ctx, parentPath)
		if err != nil {
			return nil, fs.ErrNotExist
		}
		fileName := name[index+1:]
		id = uuid.New()
		if err = a.lib.CreateResource(ctx, id, parent.ID, fileName, false); err != nil {
			return nil, err
		}
	}

	return a.lib.UpdateContents(ctx, id)
}

func (a adapter) RemoveAll(ctx context.Context, name string) error {
	resource, err := a.resourceByPath(ctx, name)
	if err != nil {
		return fs.ErrNotExist
	}
	return a.lib.DeleteRecursive(ctx, resource.ID, false)
}

func (a adapter) Mkdir(ctx context.Context, name string) error {
	if _, err := a.resourceByPath(ctx, name); err == nil {
		return fs.ErrExist
	}
	name = strings.TrimRight(name, "/")
	index := strings.LastIndex(name, "/")
	parentPath := name[0:index]
	parent, err := a.resourceByPath(ctx, parentPath)
	if err != nil {
		return fs.ErrNotExist
	}
	dirName := name[index+1:]
	err = a.lib.CreateResource(ctx, uuid.New(), parent.ID, dirName, true)
	return err
}
func (a adapter) Copy(ctx context.Context, name, dest string, options *webdav.CopyOptions) (created bool, err error) {
	// TODO: Implement
	return false, webdav.NewHTTPError(http.StatusMethodNotAllowed, fmt.Errorf("not implemented"))
}
func (a adapter) Move(ctx context.Context, name, destName string, options *webdav.MoveOptions) (created bool, err error) {
	src, err := a.resourceByPath(ctx, name)
	if err != nil {
		return false, fs.ErrNotExist
	}

	existing, err := a.resourceByPath(ctx, destName)
	if err == nil {
		if options.NoOverwrite {
			return false, fs.ErrExist
		} else {
			a.lib.DeleteRecursive(ctx, existing.ID, false)
		}
	}

	destName = strings.TrimRight(destName, "/")
	index := strings.LastIndex(destName, "/")
	parentPath := destName[0:index]
	parent, err := a.resourceByPath(ctx, parentPath)
	destName = destName[index+1:]

	if err != nil {
		return false, webdav.NewHTTPError(http.StatusConflict, nil)
	}

	if err = a.lib.Move(ctx, src.ID, parent.ID, destName); err != nil {
		return false, err
	}
	return true, nil
}

func (a adapter) resourceByPath(ctx context.Context, name string) (res sql.ResourceByPathRow, err error) {
	return a.lib.ResourceByPath(ctx, strings.TrimPrefix(name, a.prefix))
}
