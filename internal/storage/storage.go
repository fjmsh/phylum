package storage

import (
	"github.com/google/uuid"
)

type Storage interface {
	Open(id uuid.UUID, flag int, writeCallback func(int, string) error) (ReadWriteSeekCloser, error)
	Delete(id uuid.UUID) error
	String() string
}
