package storage

import (
	"io"
)

type Backend interface {
	Name() string
	OpenRead(name string, start, length int) (io.ReadCloser, error)
	Delete(name string) error
	DeleteAll(names []string) []error
	Copy(name string, src Backend) error
}

type LocalBackend interface {
	Backend
	OpenWrite(name string) (io.WriteCloser, error)
	path(name string) string
}
