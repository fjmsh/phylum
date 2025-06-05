package storage

import (
	"io"
)

type Backend interface {
	OpenRead(name string, start, length int) (io.ReadCloser, error)
	Delete(name string) error
	DeleteAll(names []string) []error
	move(localPath, name string) error
}

type LocalBackend interface {
	Backend
	OpenWrite(name string) (io.WriteCloser, error)
	Move(name string, target Backend) error
}
