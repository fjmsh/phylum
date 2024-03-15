package storage

import (
	"github.com/google/uuid"
)

type Storage interface {
	Open(id uuid.UUID, write bool, callback func(int, string) error) (ReadWriteSeekCloser, error)
	Delete(id uuid.UUID) error
	String() string
}
