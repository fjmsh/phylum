package storage

import (
	"errors"
	"io"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/sql"
)

type Storage interface {
	OpenRead(id uuid.UUID, start, length int64) (io.ReadCloser, error)
	OpenWrite(id uuid.UUID, callback func(int, string) error) (io.WriteCloser, error)
	Delete(rows []sql.HardDeleteRecursiveRow) []error
	String() string
}

func Open(driver string, params map[string]string) (Storage, error) {
	switch driver {
	case "local":
		return newLocalStorage(params["root"])
	case "minio":
		return newMinioStorage(
			params["endpoint"],
			params["key_id"],
			params["access_key"],
			params["tmp"],
			params["bucket_name"],
			params["prefix"],
		)

	}
	return nil, errors.New("unrecognized storage driver: " + driver)
}

func ParamNames(driver string) ([]string, error) {
	switch driver {
	case "local":
		return []string{"root"}, nil
	case "minio":
		return []string{"endpoint", "key_id", "access_key", "tmp", "bucket_name", "prefix"}, nil
	}
	return nil, errors.New("unrecognized storage driver: " + driver)
}
