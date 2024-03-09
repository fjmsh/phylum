package webdav

import (
	"context"
	"io"
	"io/fs"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/library"
	"golang.org/x/net/webdav"
)

type adapter struct {
	lib *library.Library
}

func (a adapter) Stat(ctx context.Context, name string) (os.FileInfo, error) {
	resource, err := a.lib.ResourceByPath(ctx, name)
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

func (a adapter) OpenFile(ctx context.Context, name string, flag int, perm os.FileMode) (webdav.File, error) {
	resource, err := a.lib.ResourceByPath(ctx, name)
	resourceId := resource.ID
	resourceName := resource.Name
	size := resource.Size.Int32
	modTime := resource.Modified.Time
	dir := resource.Dir
	if err != nil {
		if flag&os.O_CREATE == 0 {
			return nil, err
		}
		name = strings.TrimRight(name, "/")
		index := strings.LastIndex(name, "/")
		parentPath := name[0:index]
		parent, err := a.lib.ResourceByPath(ctx, parentPath)
		if err != nil {
			return nil, fs.ErrNotExist
		}
		resourceName := name[index+1:]
		resourceId = uuid.New()
		dir = false
		modTime = time.Time{}
		err = a.lib.CreateResource(ctx, resourceId, parent.ID, resourceName, dir)
		if err != nil {
			return nil, err
		}
	}
	var src io.ReadWriteCloser
	if !dir {
		src, err = a.lib.Open(resourceId, flag)
		if err != nil {
			return nil, err
		}
	}
	return file{
		fileInfo: fileInfo{
			name:       resourceName,
			size:       int64(size),
			modTime:    modTime,
			dir:        dir,
			resourceID: resourceId,
		},
		src: src,
		lib: a.lib,
	}, nil
}

func (a adapter) Create(ctx context.Context, name string) (io.WriteCloser, error) {
	var id uuid.UUID
	if resource, err := a.lib.ResourceByPath(ctx, name); err == nil {
		id = resource.ID
	} else {
		name = strings.TrimRight(name, "/")
		index := strings.LastIndex(name, "/")
		parentPath := name[0:index]
		parent, err := a.lib.ResourceByPath(ctx, parentPath)
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
	resource, err := a.lib.ResourceByPath(ctx, name)
	if err != nil {
		return fs.ErrNotExist
	}
	return a.lib.DeleteRecursive(ctx, resource.ID, false)
}

func (a adapter) Mkdir(ctx context.Context, name string, mode fs.FileMode) error {
	if _, err := a.lib.ResourceByPath(ctx, name); err == nil {
		return fs.ErrExist
	}
	name = strings.TrimRight(name, "/")
	index := strings.LastIndex(name, "/")
	parentPath := name[0:index]
	parent, err := a.lib.ResourceByPath(ctx, parentPath)
	if err != nil {
		return fs.ErrNotExist
	}
	dirName := name[index+1:]
	err = a.lib.CreateResource(ctx, uuid.New(), parent.ID, dirName, true)
	return err
}

func (a adapter) Rename(ctx context.Context, oldName, newName string) error {
	src, err := a.lib.ResourceByPath(ctx, oldName)
	if err != nil {
		return fs.ErrNotExist
	}

	_, err = a.lib.ResourceByPath(ctx, newName)
	if err == nil {
		return fs.ErrExist
	}

	newName = strings.TrimRight(newName, "/")
	index := strings.LastIndex(newName, "/")
	parentPath := newName[0:index]
	parent, err := a.lib.ResourceByPath(ctx, parentPath)
	newName = newName[index+1:]

	if err != nil {
		return fs.ErrNotExist
	}

	if err = a.lib.Move(ctx, src.ID, parent.ID, newName); err != nil {
		return err
	}
	return nil
}
