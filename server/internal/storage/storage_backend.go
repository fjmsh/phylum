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
	Copy(ctx context.Context, src Backend, srcName, destName string) error
}

type LocalBackend interface {
	Backend
	Write(name string, contents io.Reader) (WrittenFile, error)
	Path(name string) string
}
