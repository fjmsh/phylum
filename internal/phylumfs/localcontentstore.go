package phylumfs

import (
	"crypto/md5"
	"hash"
	"io"
	"os"
	"path/filepath"

	"github.com/google/uuid"
)

type LocalContentStore string

type contentWriter struct {
	file     *os.File
	hash     hash.Hash
	len      **int
	callback func(hash.Hash, int, error)
}

func (c contentWriter) Write(p []byte) (n int, err error) {
	n, err = c.file.Write(p)
	len := **c.len + n
	*c.len = &len
	c.hash.Write(p)
	return
}

func (c contentWriter) Close() error {
	err := c.file.Sync()
	if err != nil {
		return err
	}
	err = c.file.Close()
	c.callback(c.hash, **c.len, err)
	return err
}

func NewLocalContentStore(root string) (ContentStore, error) {
	err := os.MkdirAll(root, 0750)
	if err != nil {
		return nil, err
	}
	return LocalContentStore(root), nil
}

func (l LocalContentStore) Open(id uuid.UUID) (io.ReadCloser, error) {
	return os.Open(l.path(id))
}

func (l LocalContentStore) Create(id uuid.UUID, callback func(hash.Hash, int, error)) (io.WriteCloser, error) {
	file, err := os.Create(l.path(id))
	if err != nil {
		return nil, err
	}
	len := 0
	addr := &len
	return contentWriter{file, md5.New(), &addr, callback}, nil
}

func (l LocalContentStore) Delete(id uuid.UUID) error {
	return os.Remove(filepath.Join(string(l), id.String()))
}

func (l LocalContentStore) path(id uuid.UUID) string {
	return filepath.Join(string(l), id.String())
}
