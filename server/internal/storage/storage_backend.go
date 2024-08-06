package storage

import (
	"io"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/db"
)

type Backend interface {
	Name() string
	OpenRead(id uuid.UUID, start, length int64) (io.ReadCloser, error)
	OpenWrite(id uuid.UUID, callback func(int, string) error) (io.WriteCloser, error)
	Delete(rows []db.HardDeleteRecursiveRow) []error
	String() string
}
