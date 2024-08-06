package storage

import (
	"io"

	"github.com/google/uuid"
)

type Backend interface {
	Name() string
	OpenRead(id uuid.UUID, start, length int64) (io.ReadCloser, error)
	OpenWrite(id uuid.UUID, callback func(int, string) error) (io.WriteCloser, error)
	Delete(id uuid.UUID) error
	DeleteAll(ids uuid.UUIDs) []error
	String() string
}
