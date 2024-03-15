package storage

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"hash"
	"os"
	"path/filepath"

	"github.com/google/uuid"
)

type localStorage string

func newLocalStorage(root string) (Storage, error) {
	if root == "" {
		return nil, errors.New("local storage root not provided")
	}
	err := os.MkdirAll(root, 0750)
	if err != nil {
		return nil, err
	}
	return localStorage(root), nil
}

func (l localStorage) Open(id uuid.UUID, write bool, callback func(int, string) error) (ReadWriteSeekCloser, error) {
	if !write {
		return os.OpenFile(l.path(id), os.O_RDONLY, 0640)
	}

	file, err := os.OpenFile(l.path(id), os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0640)
	if err != nil || callback == nil {
		return file, err
	}
	return &hasher{dest: file, sum: md5.New(), closeCallback: func(len int, sum hash.Hash, err error) error {
		if err != nil {
			return err
		}
		etag := hex.EncodeToString(sum.Sum(nil))
		return callback(len, etag)
	}}, nil
}

func (l localStorage) Delete(id uuid.UUID) error {
	return os.Remove(l.path(id))
}

func (l localStorage) path(id uuid.UUID) string {
	return filepath.Join(string(l), id.String())
}

func (l localStorage) String() string {
	return "local (" + string(l) + ")"
}
