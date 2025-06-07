package storage

import (
	"errors"
	"io"
	"io/fs"
	"os"
	"path/filepath"
)

type localStorage struct {
	name string
	root string
}

func createLocalBackend(name string, params map[string]string) (LocalBackend, error) {
	if params["root"] == "" {
		return nil, errors.New("local storage root not provided")
	}

	l := localStorage{
		name: name,
		root: params["root"],
	}

	if err := os.MkdirAll(l.root, 0700); err != nil {
		return nil, errors.New("failed to create root directory: " + err.Error())
	}

	return l, nil
}
func (l localStorage) Name() string {
	return l.name
}

func (l localStorage) OpenRead(name string, start, length int) (io.ReadCloser, error) {
	file, err := os.OpenFile(l.path(name), os.O_RDONLY, 0640)
	if err != nil {
		return nil, err
	}
	_, err = file.Seek(int64(start), io.SeekStart)
	if err != nil {
		return nil, err
	}
	return file, nil
}

func (l localStorage) OpenWrite(name string) (io.WriteCloser, error) {
	f, err := os.CreateTemp(tempDir, "phylum-*")
	if err != nil {
		return nil, err
	}
	return &callbackWriteCloser{dest: f, closeCallback: func(err error) error {
		if err != nil {
			os.Remove(f.Name())
			return err
		}
		return os.Rename(f.Name(), l.path(name))
	}}, nil
}

func (l localStorage) Copy(name string, src Backend) error {
	if src == l {
		return errors.New("cannot copy to self")
	}
	in, err := src.OpenRead(name, 0, -1)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := l.OpenWrite(name)
	if err != nil {
		return err
	}
	_, copyErr := io.Copy(out, in)
	closeErr := out.Close()
	if copyErr != nil {
		return copyErr
	}
	return closeErr
}

func (l localStorage) Delete(name string) error {
	return os.Remove(l.path(name))
}

func (l localStorage) DeleteAll(names []string) []error {
	errs := make([]error, 0)
	for _, name := range names {
		err := l.Delete(name)
		if err != nil && !errors.Is(err, fs.ErrNotExist) {
			errs = append(errs, err)
		}
	}
	return errs
}

func (l localStorage) path(name string) string {
	return filepath.Join(l.root, name)
}

func (l localStorage) String() string {
	return "local (" + string(l.root) + ")"
}
