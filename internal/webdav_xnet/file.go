package webdav

import (
	"context"
	"fmt"
	"io"
	"io/fs"

	"github.com/shroff/phylum/server/internal/library"
)

type file struct {
	fileInfo
	src io.ReadWriteCloser
	lib *library.Library
}

func (f file) Seek(offset int64, whence int) (int64, error) {
	return 0, fmt.Errorf("seek not supported")
}
func (f file) Read(p []byte) (n int, err error) {
	return f.src.Read(p)
}
func (f file) Close() error {
	if f.src == nil {
		return nil
	}
	return f.src.Close()
}
func (f file) Write(p []byte) (n int, err error) {
	return f.src.Write(p)
}

func (f file) Readdir(count int) ([]fs.FileInfo, error) {
	if !f.dir {
		return nil, fmt.Errorf("readdir not supported for non-collection resources")
	}

	children, err := f.lib.ReadDir(context.Background(), f.resourceID, false, false)
	if err != nil {
		return nil, err
	}

	result := make([]fs.FileInfo, len(children))
	for i, c := range children {
		result[i] = fileInfo{
			name:       c.Name,
			size:       int64(c.Size.Int32),
			modTime:    c.Modified.Time,
			dir:        c.Dir,
			resourceID: c.ID,
		}
	}
	return result, nil

}
func (f file) Stat() (fs.FileInfo, error) {
	return f, nil
}
