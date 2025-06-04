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
	root string
	tmp  string
}

func createLocalBackend(params map[string]string) (LocalBackend, error) {
	if params["root"] == "" {
		return nil, errors.New("local storage root not provided")
	}

	l := localStorage{
		root: params["root"],
		tmp:  filepath.Join(params["root"], "tmp"),
	}

	if err := os.RemoveAll(l.tmp); err != nil {
		return nil, errors.New("failed to remove tmp directory: " + err.Error())
	}
	if err := os.MkdirAll(l.tmp, 0750); err != nil {
		return nil, errors.New("failed to create tmp directory: " + err.Error())
	}

	return l, nil
}

func (l localStorage) OpenRead(id uuid.UUID, start, length int) (io.ReadCloser, error) {
	file, err := os.OpenFile(l.path(id), os.O_RDONLY, 0640)
	if err != nil {
		return nil, err
	}
	_, err = file.Seek(int64(start), io.SeekStart)
	if err != nil {
		return nil, err
	}
	return file, nil
}

func (l localStorage) OpenWrite(id uuid.UUID) (io.WriteCloser, error) {
	f, err := os.CreateTemp(l.tmp, "upload-*")
	tmpFilePath := filepath.Join(l.tmp, f.Name())
	if err != nil {
		return nil, err
	}
	return &callbackWriteCloser{dest: f, closeCallback: func(err error) error {
		if err != nil {
			os.Remove(tmpFilePath)
			return err
		}
		return os.Rename(tmpFilePath, l.path(id))
	}}, nil
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
