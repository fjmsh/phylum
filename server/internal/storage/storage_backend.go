package storage

import (
	"io"
)

type Backend interface {
	OpenRead(name string, start, length int) (io.ReadCloser, error)
	Delete(name string) error
	DeleteAll(names []string) []error
	String() string
}

type LocalBackend interface {
	Backend
	OpenWrite(name string) (io.WriteCloser, error)
}
