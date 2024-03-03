package pgfs

import (
	"hash"
	"io"

	"github.com/google/uuid"
)

type ContentStore interface {
	Open(id uuid.UUID) (io.ReadCloser, error)
	Create(id uuid.UUID, callback func(hash.Hash, error)) (io.WriteCloser, error)
	Delete(id uuid.UUID) error
}
