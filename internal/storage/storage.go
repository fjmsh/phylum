package storage

import (
	"hash"
	"io"
	"os"

	"github.com/google/uuid"
)

type Storage interface {
	Open(id uuid.UUID) (io.ReadCloser, error)
	Create(id uuid.UUID, callback func(hash.Hash, int, error)) (io.WriteCloser, error)
	Delete(id uuid.UUID) error
}

func NewLocalStorage(root string) (Storage, error) {
	err := os.MkdirAll(root, 0750)
	if err != nil {
		return nil, err
	}
	return localStorage(root), nil
}
