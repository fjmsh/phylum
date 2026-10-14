package storage

import (
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
)

var ErrDuplicateWrite = errors.New("duplicate write")

type localStorage struct {
	name string
	root string
	tmp  string
}

func createLocalBackend(name string, params map[string]string) (LocalBackend, error) {
	if params["root"] == "" {
		return nil, errors.New("local storage root not provided")
	}

	root := params["root"]
	if !filepath.IsAbs(root) {
		root = filepath.Join(Root, root)
	}
	l := localStorage{
		name: name,
		root: root,
		tmp:  filepath.Join(root, "tmp"),
	}

	if err := os.MkdirAll(l.root, 0o700); err != nil {
		return nil, fmt.Errorf("failed to create root directory for storage backend `%s`: %w", name, err)
	}

	if err := os.RemoveAll(l.tmp); err != nil {
		return nil, fmt.Errorf("failed to clear temp directory for storage backend `%s`: %w", name, err)
	}
	if err := os.MkdirAll(l.tmp, 0o700); err != nil {
		return nil, fmt.Errorf("failed to create temp directory for storage backend `%s`: %w", name, err)
	}

	return l, nil
}
func (l localStorage) Name() string {
	return l.name
}

func (l localStorage) OpenRead(name string, start, length int) (io.ReadCloser, error) {
	file, err := os.OpenFile(l.Path(name), os.O_RDONLY, 0640)
	if err != nil {
		return nil, err
	}
	_, err = file.Seek(int64(start), io.SeekStart)
	if err != nil {
		return nil, err
	}
	return file, nil
}

func (l localStorage) OpenWrite(name string, writeFinishedCallback func(io.ReadSeeker) error) (io.WriteCloser, error) {
	f, err := os.CreateTemp(l.tmp, "upload-*")
	if err != nil {
		return nil, err
	}
	return &callbackWriteCloser{dest: f, closeCallback: func(err error) error {
		defer os.Remove(f.Name())
		if err != nil {
			return err
		}
		if in, err := os.Open(f.Name()); err != nil {
			return err
		} else {
			defer in.Close()
			if err := writeFinishedCallback(in); err != nil {
				if errors.Is(err, ErrDuplicateWrite) {
					return nil
				}
				return err
			} else if err := l.mkdirs(name); err != nil {
				return err
			}
		}
		return os.Rename(f.Name(), l.Path(name))
	}}, nil
}

func (l localStorage) Copy(ctx context.Context, src Backend, srcName, destName string) error {
	if src == l && srcName == destName {
		return errors.New("cannot copy to self")
	}
	in, err := src.OpenRead(srcName, 0, -1)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := l.OpenWrite(destName, func(_ io.ReadSeeker) error { return nil })
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
	return os.Remove(l.Path(name))
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

func (l localStorage) oldPath(name string) string {
	return filepath.Join(l.root, name)
}

func (l localStorage) mkdirs(name string) error {
	return os.MkdirAll(filepath.Join(l.root, name[len(name)-2:]), 0o700)
}

func (l localStorage) Path(name string) string {
	return filepath.Join(l.root, name[len(name)-2:], name[0:len(name)-2])
}

func (l localStorage) String() string {
	return "local (root: " + string(l.root) + ")"
}
