// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package webdav

import (
	"github.com/shroff/phylum/server/internal/core/fs"
)

type WalkFunc func(r fs.Resource) error

func walkFS(fs FileSystem, depth int, r fs.Resource, walkFn WalkFunc) error {
	err := walkFn(r)
	if err != nil {
		return err
	}
	if !r.Dir || depth <= 0 {
		return nil
	}

	children, err := fs.ReadDir(r, depth > 1)
	if err != nil {
		return err
	}

	for _, c := range children {
		if err := walkFn(c); err != nil {
			return err
		}
	}
	return nil
}
