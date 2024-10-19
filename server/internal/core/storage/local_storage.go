package storage

import (
	"errors"
	"io"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/google/uuid"
)

type localStorage struct {
	name string
	root string
}

func newLocalStorage(name, root string) (Backend, error) {
	if root == "" {
		return nil, errors.New("local storage root not provided")
	}
	err := os.MkdirAll(root, 0750)
	if err != nil {
		return nil, err
	}
	return localStorage{name: name, root: root}, nil
}

func (l localStorage) Name() string {
	return l.name
}

func (l localStorage) OpenRead(id uuid.UUID, start, length int64) (io.ReadCloser, error) {
	file, err := os.OpenFile(l.path(id), os.O_RDONLY, 0640)
	if err != nil {
		return nil, err
	}
	_, err = file.Seek(start, io.SeekStart)
	if err != nil {
		return nil, err
	}
	return file, nil
}

func (l localStorage) OpenWrite(id uuid.UUID) (io.WriteCloser, error) {
	return os.OpenFile(l.path(id), os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0640)
}

func (l localStorage) Delete(id uuid.UUID) error {
	return os.Remove(l.path(id))
}

func (l localStorage) DeleteAll(ids uuid.UUIDs) []error {
	errs := make([]error, 0)
	for _, id := range ids {
		err := l.Delete(id)
		if err != nil && !errors.Is(err, fs.ErrNotExist) {
			errs = append(errs, err)
		}
	}
	return errs
}

func (l localStorage) path(id uuid.UUID) string {
	return filepath.Join(string(l.root), id.String())
}

func (l localStorage) String() string {
	return "local (" + string(l.root) + ")"
}
