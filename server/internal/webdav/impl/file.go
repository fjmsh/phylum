// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package webdav

import (
	"context"
	"io"
	"net/http"
	"path"
	"path/filepath"

	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/core"
)

// A FileSystem implements access to a collection of named files. The elements
// in a file path are separated by slash ('/', U+002F) characters, regardless
// of host operating system convention.
type FileSystem interface {
	Stat(ctx context.Context, name string) (core.Resource, error)
	Mkdir(ctx context.Context, name string) error
	RemoveAll(ctx context.Context, name string) error
	Rename(ctx context.Context, oldName, newName string) error
	ReadDir(r core.Resource) ([]core.Resource, error)
	OpenRead(r core.Resource, start, length int64) (io.ReadCloser, error)
	OpenWrite(ctx context.Context, name string) (io.WriteCloser, error)
}

// moveFiles moves files and/or directories from src to dst.
//
// See section 9.9.4 for when various HTTP status codes apply.
func moveFiles(ctx context.Context, fs FileSystem, src, dst string, overwrite bool) (status int, err error) {
	created := false
	if _, err := fs.Stat(ctx, dst); err != nil {
		if !errors.Is(err, core.ErrResourceNotFound) {
			if e, ok := err.(errors.ApiErr); ok {
				return e.Status, e
			}
			return http.StatusForbidden, err
		}
		created = true
	} else if overwrite {
		// Section 9.9.3 says that "If a resource exists at the destination
		// and the Overwrite header is "T", then prior to performing the move,
		// the server must perform a DELETE with "Depth: infinity" on the
		// destination resource.
		if err := fs.RemoveAll(ctx, dst); err != nil {
			return http.StatusForbidden, err
		}
	} else {
		return http.StatusPreconditionFailed, core.ErrResourceNameConflict
	}
	if err := fs.Rename(ctx, src, dst); err != nil {
		return http.StatusForbidden, err
	}
	if created {
		return http.StatusCreated, nil
	}
	return http.StatusNoContent, nil
}

// copyFiles copies files and/or directories from src to dst.
//
// See section 9.8.5 for when various HTTP status codes apply.
func copyFiles(ctx context.Context, fs FileSystem, src, dst string, overwrite bool, depth int) (status int, err error) {
	srcStat, err := fs.Stat(ctx, src)
	if err != nil {
		if errors.Is(err, core.ErrResourceNotFound) {
			return http.StatusNotFound, err
		}
		return http.StatusInternalServerError, err
	}

	created := false
	if _, err := fs.Stat(ctx, dst); err != nil {
		if errors.Is(err, core.ErrResourceNotFound) {
			created = true
		} else {
			return http.StatusForbidden, err
		}
	} else {
		if !overwrite {
			return http.StatusPreconditionFailed, core.ErrResourceNameConflict
		}
		if err := fs.RemoveAll(ctx, dst); err != nil && !errors.Is(err, core.ErrResourceNotFound) {
			return http.StatusForbidden, err
		}
	}

	if srcStat.Dir {
		if err := fs.Mkdir(ctx, dst); err != nil {
			return http.StatusForbidden, err
		}
		if depth == infiniteDepth {
			children, err := fs.ReadDir(srcStat)
			if err != nil {
				return http.StatusForbidden, err
			}
			for _, c := range children {
				name := c.Name
				s := path.Join(src, name)
				d := path.Join(dst, name)
				cStatus, cErr := copyFiles(ctx, fs, s, d, overwrite, depth)
				if cErr != nil {
					// TODO: MultiStatus.
					return cStatus, cErr
				}
			}
		}

	} else {
		srcFile, err := fs.OpenRead(srcStat, 0, -1)
		if err != nil {
			if errors.Is(err, core.ErrResourceNotFound) {
				return http.StatusNotFound, err
			}
			return http.StatusInternalServerError, err
		}
		defer srcFile.Close()
		dstFile, err := fs.OpenWrite(ctx, dst)
		if err != nil {
			if errors.Is(err, core.ErrResourceNotFound) {
				return http.StatusConflict, err
			}
			return http.StatusForbidden, err

		}
		_, copyErr := io.Copy(dstFile, srcFile)
		closeErr := dstFile.Close()
		if copyErr != nil {
			return http.StatusInternalServerError, copyErr
		}
		if closeErr != nil {
			return http.StatusInternalServerError, closeErr
		}
	}

	if created {
		return http.StatusCreated, nil
	}
	return http.StatusNoContent, nil
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
