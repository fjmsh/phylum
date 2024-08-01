package core

import (
	"io"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/sql"
)

type Storage interface {
	Name() string
	OpenRead(id uuid.UUID, start, length int64) (io.ReadCloser, error)
	OpenWrite(id uuid.UUID, callback func(int, string) error) (io.WriteCloser, error)
	Delete(rows []sql.HardDeleteRecursiveRow) []error
	String() string
}
