package storage

import (
	"context"
	"io"
)

type Backend interface {
	Name() string
	OpenRead(name string, start, length int) (io.ReadCloser, error)
	Delete(name string) error
	DeleteAll(names []string) []error
	Copy(ctx context.Context, name string, src Backend) error
}

type LocalBackend interface {
	Backend
	OpenWrite(name string) (io.WriteCloser, error)
	path(name string) string
}
