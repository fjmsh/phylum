package storage

import (
	"io"

	"github.com/google/uuid"
)

type Backend interface {
	OpenRead(id uuid.UUID, start, length int) (io.ReadCloser, error)
	Delete(id uuid.UUID) error
	DeleteAll(ids uuid.UUIDs) []error
	String() string
}

type LocalBackend interface {
	Backend
	OpenWrite(id uuid.UUID) (io.WriteCloser, error)
}
