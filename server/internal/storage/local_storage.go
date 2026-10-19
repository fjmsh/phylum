package storage

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
)

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

func (l localStorage) Write(name string, in io.Reader) (WrittenFile, error) {
	hash := sha256.New()
	tee := io.TeeReader(in, hash)
	var size int64
	var tempName string
	if temp, err := os.CreateTemp(l.tmp, "upload-*"); err != nil {
		return WrittenFile{}, err
	} else {
		tempName = temp.Name()
		defer os.Remove(temp.Name())
		if size, err = io.Copy(temp, tee); err != nil {
			temp.Close()
			return WrittenFile{}, err
		} else if err = temp.Close(); err != nil {
			return WrittenFile{}, err
		}
	}

	if err := l.mkdirs(name); err != nil {
		return WrittenFile{}, err
	}

	// Check if a file already exists at the destination, and if it's the same.
	if stat, err := os.Stat(l.Path(name)); err == nil {
		// File already exists. Check if it's the same
		if size != stat.Size() {
			return WrittenFile{}, errors.New("file already exists with different size")
		}
		if existing, err := os.Open(l.Path(name)); err != nil {
			return WrittenFile{}, err
		} else {
			defer existing.Close()
			existingHash := sha256.New()
			if _, err = io.Copy(existingHash, existing); err != nil {
				return WrittenFile{}, err
			} else if !bytes.Equal(hash.Sum(nil), existingHash.Sum(nil)) {
				return WrittenFile{}, errors.New("file already exists with different sha256 sum")
			} else {
				// Identical file already exists. Leave it be
				return WrittenFile{
					path:      l.Path(name),
					size:      size,
					sha256Sum: hex.EncodeToString(hash.Sum(nil)),
				}, nil
			}
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return WrittenFile{}, err
	}

	if err := os.Rename(tempName, l.Path(name)); err != nil {
		return WrittenFile{}, nil
	}

	return WrittenFile{
		path:      l.Path(name),
		size:      size,
		sha256Sum: hex.EncodeToString(hash.Sum(nil)),
	}, nil
}

type WrittenFile struct {
	path      string
	size      int64
	sha256Sum string
}

func (w WrittenFile) Size() int64 {
	return w.size
}

func (w WrittenFile) SHA256Sum() string {
	return w.sha256Sum
}

func (w WrittenFile) OpenRead() (io.ReadSeekCloser, error) {
	return os.Open(w.path)
}

func (w WrittenFile) Delete() error {
	return os.Remove(w.path)
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

	_, err = l.Write(destName, in)
	return err
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
