package webdav

import (
	"context"
	"fmt"
	"io"
	iofs "io/fs"
	"os"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/vfs"
	"golang.org/x/net/webdav"
)

type adapter struct {
	fs *vfs.Vfs
}

func (p adapter) Stat(ctx context.Context, name string) (os.FileInfo, error) {
	resource, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	val := fileInfo{
		name:       resource.Name,
		size:       int64(resource.Size.Int32),
		modTime:    resource.Modified.Time,
		dir:        resource.Dir,
		resourceID: resource.ID,
	}
	return val, nil
}

func (p adapter) OpenFile(ctx context.Context, name string, flag int, perm os.FileMode) (webdav.File, error) {
	resource, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	var src io.ReadWriteCloser
	if flag != 0 {
		src, err = p.fs.Open(resource.ID, flag)
		if err != nil {
			return nil, err
		}
	}
	return file{
		fileInfo: fileInfo{
			name:       resource.Name,
			size:       int64(resource.Size.Int32),
			modTime:    resource.Modified.Time,
			dir:        resource.Dir,
			resourceID: resource.ID,
		},
		src: src,
		fs:  p.fs,
	}, nil
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

func (p adapter) Mkdir(ctx context.Context, name string, mode iofs.FileMode) error {
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

func (p adapter) Rename(ctx context.Context, oldName, newName string) error {
	src, err := p.resourceByPath(ctx, oldName)
	if err != nil {
		return iofs.ErrNotExist
	}

	_, err = p.resourceByPath(ctx, newName)
	if err == nil {
		return iofs.ErrExist
	}

	newName = strings.TrimRight(newName, "/")
	index := strings.LastIndex(newName, "/")
	parentPath := newName[0:index]
	parent, err := p.resourceByPath(ctx, parentPath)
	newName = newName[index+1:]

	if err != nil {
		return fmt.Errorf("parent collection does not exist")
	}

	if err = p.fs.Move(ctx, src.ID, parent.ID); err != nil {
		return err
	}
	return nil
}

func (p adapter) resourceByPath(ctx context.Context, name string) (res sql.ResourceByPathRow, err error) {
	return p.fs.ResourceByPath(ctx, name)
}
