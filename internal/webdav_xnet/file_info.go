package webdav

import (
	"os"
	"time"

	"github.com/google/uuid"
)

type fileInfo struct {
	name       string
	size       int64
	dir        bool
	modTime    time.Time
	resourceID uuid.UUID
}

func (f fileInfo) Name() string {
	return f.name
}
func (f fileInfo) Size() int64 {
	return f.size
}
func (f fileInfo) Mode() os.FileMode {
	if f.dir {
		return os.ModeDir
	}
	return 0
}
func (f fileInfo) ModTime() time.Time { return f.modTime }
func (f fileInfo) IsDir() bool        { return f.dir }
func (f fileInfo) Sys() any           { return f.resourceID }
