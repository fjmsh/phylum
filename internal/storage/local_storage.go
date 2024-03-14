package storage

import (
	"crypto/md5"
	"errors"
	"hash"
	"io"
	"os"
	"path/filepath"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
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

func (l localStorage) Open(id uuid.UUID, flag int, closeCallback func(hash.Hash, int, error)) (file io.ReadWriteCloser, err error) {
	file, err = os.OpenFile(l.path(id), flag, 0640)
	if err != nil {
		logrus.Fatal(err)
	}
	if closeCallback == nil {
		return
	}
	if err != nil {
		return nil, err
	}
	len := 0
	addr := &len
	return hasher{file, md5.New(), &addr, closeCallback}, nil
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
