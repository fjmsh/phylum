package webdav

import (
	"context"
	"fmt"
	"io"
	iofs "io/fs"
	"net/http"
	"os"
	"strings"

	webdav "github.com/emersion/go-webdav"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/vfs"
)

type adapter struct {
	fs     *vfs.Vfs
	prefix string
}

func (p adapter) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	resource, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	return p.fs.Open(resource.ID, os.O_RDONLY)
}

func (p adapter) Stat(ctx context.Context, name string) (*webdav.FileInfo, error) {
	resource, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	val := &webdav.FileInfo{
		Path:     string(p.prefix + resource.Path),
		Size:     int64(resource.Size.Int32),
		ModTime:  resource.Modified.Time,
		IsDir:    resource.Dir,
		MIMEType: resource.Name,
		ETag:     resource.Etag.String,
	}
	return val, nil
}
func (p adapter) ReadDir(ctx context.Context, name string, recursive bool) ([]webdav.FileInfo, error) {
	dir, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	if !dir.Dir {
		return nil, iofs.ErrInvalid
	}
	children, err := p.fs.ReadDir(ctx, dir.ID, false, recursive)
	if err != nil {
		return nil, err
	}

	result := make([]webdav.FileInfo, len(children))
	prefix := p.prefix + dir.Path
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
func (p adapter) Create(ctx context.Context, name string) (io.WriteCloser, error) {
	var id uuid.UUID
	if resource, err := p.resourceByPath(ctx, name); err == nil {
		id = resource.ID
	} else {
		name = strings.TrimRight(name, "/")
		index := strings.LastIndex(name, "/")
		parentPath := name[0:index]
		parent, err := p.resourceByPath(ctx, parentPath)
		if err != nil {
			return nil, iofs.ErrNotExist
		}
		fileName := name[index+1:]
		id = uuid.New()
		if err = p.fs.CreateResource(ctx, id, parent.ID, fileName, false); err != nil {
			return nil, err
		}
	}

	return p.fs.UpdateContents(ctx, id)
}

func (p adapter) RemoveAll(ctx context.Context, name string) error {
	resource, err := p.resourceByPath(ctx, name)
	if err != nil {
		return iofs.ErrNotExist
	}
	return p.fs.DeleteRecursive(ctx, resource.ID, false)
}

func (p adapter) Mkdir(ctx context.Context, name string) error {
	if _, err := p.resourceByPath(ctx, name); err == nil {
		return iofs.ErrExist
	}
	name = strings.TrimRight(name, "/")
	index := strings.LastIndex(name, "/")
	parentPath := name[0:index]
	parent, err := p.resourceByPath(ctx, parentPath)
	if err != nil {
		return iofs.ErrNotExist
	}
	dirName := name[index+1:]
	err = p.fs.CreateResource(ctx, uuid.New(), parent.ID, dirName, true)
	return err
}
func (p adapter) Copy(ctx context.Context, name, dest string, options *webdav.CopyOptions) (created bool, err error) {
	// TODO: Implement
	return false, webdav.NewHTTPError(http.StatusMethodNotAllowed, fmt.Errorf("not implemented"))
}
func (p adapter) Move(ctx context.Context, name, destName string, options *webdav.MoveOptions) (created bool, err error) {
	src, err := p.resourceByPath(ctx, name)
	if err != nil {
		return false, iofs.ErrNotExist
	}

	existing, err := p.resourceByPath(ctx, destName)
	if err == nil {
		if options.NoOverwrite {
			return false, iofs.ErrExist
		} else {
			p.fs.DeleteRecursive(ctx, existing.ID, false)
		}
	}

	destName = strings.TrimRight(destName, "/")
	index := strings.LastIndex(destName, "/")
	parentPath := destName[0:index]
	parent, err := p.resourceByPath(ctx, parentPath)

	if err != nil {
		return false, webdav.NewHTTPError(http.StatusConflict, nil)
	}

	if err = p.fs.Move(ctx, src.ID, parent.ID); err != nil {
		return false, err
	}
	return true, nil
}

func (p adapter) resourceByPath(ctx context.Context, name string) (res sql.ResourceByPathRow, err error) {
	return p.fs.ResourceByPath(ctx, strings.TrimPrefix(name, p.prefix))
}
