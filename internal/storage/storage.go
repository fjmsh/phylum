package storage

import (
	"hash"
	"io"

	"github.com/google/uuid"
)

type Storage interface {
	Open(id uuid.UUID, flag int, closeCallback func(hash.Hash, int, error)) (io.ReadWriteCloser, error)
	Delete(id uuid.UUID) error
	String() string
}
