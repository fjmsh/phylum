package pgfs

import (
	"context"
	"io"
	"io/fs"
	"strings"

	webdav "github.com/emersion/go-webdav"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/phylumfs"
	"github.com/shroff/phylum/server/internal/phylumsql"
)

type Pgfs struct {
	p      phylumfs.PhylumFs
	prefix string
}

func New(p phylumfs.PhylumFs, prefix string) Pgfs {
	return Pgfs{p: p, prefix: prefix}
}

func (p Pgfs) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	resource, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	return p.p.Open(resource.ID)
}

func (p Pgfs) Stat(ctx context.Context, name string) (*webdav.FileInfo, error) {
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
func (p Pgfs) ReadDir(ctx context.Context, name string, recursive bool) ([]webdav.FileInfo, error) {
	dir, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	if !dir.Dir {
		return nil, fs.ErrInvalid
	}
	children, err := p.p.ReadDir(ctx, dir.ID, recursive)
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
func (p Pgfs) Create(ctx context.Context, name string) (io.WriteCloser, error) {
	var id uuid.UUID
	if resource, err := p.resourceByPath(ctx, name); err == nil {
		id = resource.ID
	} else {
		name = strings.TrimRight(name, "/")
		index := strings.LastIndex(name, "/")
		parentPath := name[0:index]
		parent, err := p.resourceByPath(ctx, parentPath)
		if err != nil {
			return nil, fs.ErrNotExist
		}
		fileName := name[index+1:]
		id = uuid.New()
		if err = p.p.CreateResource(ctx, id, parent.ID, fileName, false); err != nil {
			return nil, err
		}
	}

	return p.p.UpdateContents(ctx, id)
}

func (p Pgfs) RemoveAll(ctx context.Context, name string) error {
	resource, _ := p.resourceByPath(ctx, name)
	if resource == nil {
		return fs.ErrNotExist
	}
	err := p.p.DeleteRecursive(ctx, resource.ID)
	return err
}

func (p Pgfs) Mkdir(ctx context.Context, name string) error {
	resource, _ := p.resourceByPath(ctx, name)
	if resource != nil {
		return fs.ErrExist
	}
	name = strings.TrimRight(name, "/")
	index := strings.LastIndex(name, "/")
	parentPath := name[0:index]
	parent, err := p.resourceByPath(ctx, parentPath)
	if err != nil {
		return fs.ErrNotExist
	}
	dirName := name[index+1:]
	err = p.p.CreateResource(ctx, uuid.New(), parent.ID, dirName, true)
	return err
}
func (p Pgfs) Copy(ctx context.Context, name, dest string, options *webdav.CopyOptions) (created bool, err error) {
	// TODO: Implement
	return false, nil
}
func (p Pgfs) Move(ctx context.Context, name, dest string, options *webdav.MoveOptions) (created bool, err error) {
	// TODO: Implement
	return false, nil
}

func (p Pgfs) resourceByPath(ctx context.Context, name string) (res *phylumsql.ResourceByPathRow, err error) {
	return p.p.ResourceByPath(ctx, strings.TrimPrefix(name, p.prefix+"/"))
}
