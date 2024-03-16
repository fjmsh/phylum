package webdav

import (
	"context"
	"errors"
	"io"
	"io/fs"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/library"
	"github.com/shroff/phylum/server/internal/webdav"
)

type adapter struct {
	lib *library.Library
}

func (a adapter) Stat(ctx context.Context, name string) (webdav.ResourceInfo, error) {
	resource, err := a.lib.ResourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	val := resourceInfo{
		lib:        a.lib,
		name:       resource.Name,
		size:       int64(resource.Size.Int32),
		modTime:    resource.Modified.Time,
		collection: resource.Dir,
		resourceID: resource.ID,
		etag:       resource.Etag.String,
	}
	return val, nil
}

func (a adapter) OpenWrite(ctx context.Context, name string) (io.WriteCloser, error) {
	resource, err := a.lib.ResourceByPath(ctx, name)
	resourceId := resource.ID

	if err != nil {
		if err == fs.ErrNotExist {
			// Try to create the resource if the parent collection exists
			name = strings.TrimRight(name, "/")
			index := strings.LastIndex(name, "/")
			parentPath := name[0:index]
			parent, err := a.lib.ResourceByPath(ctx, parentPath)
			if err != nil {
				return nil, fs.ErrNotExist
			}
			resourceName := name[index+1:]
			resourceId = uuid.New()
			err = a.lib.CreateResource(ctx, resourceId, parent.ID, resourceName, false)
			if err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
	} else if resource.Dir {
		return nil, errors.New("cannot open collection for write")
	}
	return a.lib.Open(ctx, resourceId, true)
}

func (a adapter) RemoveAll(ctx context.Context, name string) error {
	resource, err := a.lib.ResourceByPath(ctx, name)
	if err != nil {
		return fs.ErrNotExist
	}
	return a.lib.DeleteRecursive(ctx, resource.ID, false)
}

func (a adapter) Mkdir(ctx context.Context, name string) error {
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
