// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package webdav

import (
	"path"
	"path/filepath"

	"github.com/shroff/phylum/server/internal/core/fs"
)

type WalkFunc func(path string, info fs.Resource, err error) error

// walkFS traverses filesystem fs starting at name up to depth levels.
//
// Allowed values for depth are 0, 1 or infiniteDepth. For each visited node,
// walkFS calls walkFn. If a visited file system node is a directory and
// walkFn returns filepath.SkipDir, walkFS will skip traversal of this node.
func walkFS(fs FileSystem, depth int, name string, info fs.Resource, walkFn WalkFunc) error {
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
	f, err := fs.ResourceByPath(name)
	if err != nil {
		return walkFn(name, info, err)
	}
	fileInfos, err := fs.ReadDir(f)
	if err != nil {
		return walkFn(name, info, err)
	}

	for _, fileInfo := range fileInfos {
		filename := path.Join(name, fileInfo.Name)
		fileInfo, err := fs.ResourceByPath(filename)
		if err != nil {
			if err := walkFn(filename, fileInfo, err); err != nil && err != filepath.SkipDir {
				return err
			}
		} else {
			err = walkFS(fs, depth, filename, fileInfo, walkFn)
			if err != nil {
				if !fileInfo.Dir || err != filepath.SkipDir {
					return err
				}
			}
		}
	}
	return nil
}
