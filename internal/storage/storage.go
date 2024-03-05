package storage

import (
	"hash"
	"io"
	"os"

	"github.com/google/uuid"
)

type Storage interface {
	Open(id uuid.UUID, flag int, closeCallback func(hash.Hash, int, error)) (io.ReadWriteCloser, error)
	Delete(id uuid.UUID) error
}

func NewLocalStorage(root string) (Storage, error) {
	err := os.MkdirAll(root, 0750)
	if err != nil {
		return nil, err
	}
	return localStorage(root), nil
}
