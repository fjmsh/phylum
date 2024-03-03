package pgfs

import (
	"crypto/md5"
	"hash"
	"io"
	"os"
	"path/filepath"

	"github.com/google/uuid"
)

type LocalFsContentStore string

type contentWriter struct {
	file     *os.File
	hash     hash.Hash
	callback func(hash.Hash, error)
}

func (c contentWriter) Write(p []byte) (n int, err error) {
	n, err = c.file.Write(p)
	c.hash.Write(p)
	return
}

func (c contentWriter) Close() error {
	err := c.file.Close()
	c.callback(c.hash, err)
	return err
}

func NewLocalFsContentStore(root string) (ContentStore, error) {
	err := os.MkdirAll(root, 0750)
	if err != nil {
		return nil, err
	}
	return LocalFsContentStore(root), nil
}

func (l LocalFsContentStore) Open(id uuid.UUID) (io.ReadCloser, error) {
	return os.Open(l.path(id))
}

func (l LocalFsContentStore) Create(id uuid.UUID, callback func(hash.Hash, error)) (io.WriteCloser, error) {
	file, err := os.Create(l.path(id))
	if err != nil {
		return nil, err
	}
	return contentWriter{file, md5.New(), callback}, nil
}

func (l LocalFsContentStore) Delete(id uuid.UUID) error {
	return os.Remove(filepath.Join(string(l), id.String()))
}

func (l LocalFsContentStore) path(id uuid.UUID) string {
	return filepath.Join(string(l), id.String())
}
