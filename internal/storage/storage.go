package storage

import (
	"io"

	"github.com/google/uuid"
)

type Storage interface {
	Open(id uuid.UUID, flag int, writeCallback func(int, string) error) (io.ReadWriteCloser, error)
	Delete(id uuid.UUID) error
	String() string
}
