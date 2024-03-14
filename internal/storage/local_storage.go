package storage

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"hash"
	"io"
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

func (l localStorage) Open(id uuid.UUID, flag int, writeCallback func(int, string) error) (file io.ReadWriteCloser, err error) {
	file, err = os.OpenFile(l.path(id), flag, 0640)
	if err != nil || writeCallback == nil {
		return
	}
	return &hasher{rwc: file, sum: md5.New(), closeCallback: func(len int, sum hash.Hash, err error) error {
		if err != nil {
			return err
		}
		etag := hex.EncodeToString(sum.Sum(nil))
		return writeCallback(len, etag)
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
