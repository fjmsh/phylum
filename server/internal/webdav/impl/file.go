// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package webdav

import (
	"context"
	"io"
	"path"
	"path/filepath"

	"github.com/shroff/phylum/server/internal/core"
)

// A FileSystem implements access to a collection of named files. The elements
// in a file path are separated by slash ('/', U+002F) characters, regardless
// of host operating system convention.
type FileSystem interface {
	Stat(ctx context.Context, name string) (core.Resource, error)
	Mkdir(ctx context.Context, name string) error
	RemoveAll(ctx context.Context, name string) error
	Move(ctx context.Context, r core.Resource, target string, overwrite bool) error
	Copy(ctx context.Context, r core.Resource, target string, recursive, overwrite bool) error
	ReadDir(r core.Resource) ([]core.Resource, error)
	OpenRead(r core.Resource, start, length int64) (io.ReadCloser, error)
	OpenWrite(ctx context.Context, name string) (io.WriteCloser, error)
}

type WalkFunc func(path string, info core.Resource, err error) error

// walkFS traverses filesystem fs starting at name up to depth levels.
//
// Allowed values for depth are 0, 1 or infiniteDepth. For each visited node,
// walkFS calls walkFn. If a visited file system node is a directory and
// walkFn returns filepath.SkipDir, walkFS will skip traversal of this node.
func walkFS(ctx context.Context, fs FileSystem, depth int, name string, info core.Resource, walkFn WalkFunc) error {
	// This implementation is based on Walk's code in the standard path/filepath package.
	err := walkFn(name, info, nil)
	if err != nil {
		if info.Dir && err == filepath.SkipDir {
			return nil
		}
		return err
	}
	if !info.Dir || depth == 0 {
		return nil
	}
	if depth == 1 {
		depth = 0
	}

	// Read directory names.
	f, err := fs.Stat(ctx, name)
	if err != nil {
		return walkFn(name, info, err)
	}
	fileInfos, err := fs.ReadDir(f)
	if err != nil {
		return walkFn(name, info, err)
	}

	for _, fileInfo := range fileInfos {
		filename := path.Join(name, fileInfo.Name)
		fileInfo, err := fs.Stat(ctx, filename)
		if err != nil {
			if err := walkFn(filename, fileInfo, err); err != nil && err != filepath.SkipDir {
				return err
			}
		} else {
			err = walkFS(ctx, fs, depth, filename, fileInfo, walkFn)
			if err != nil {
				if !fileInfo.Dir || err != filepath.SkipDir {
					return err
				}
			}
		}
	}
	return nil
}
