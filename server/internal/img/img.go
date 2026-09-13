package img

import (
	"errors"
	"io"
	"os"
	"path/filepath"

	"codeberg.org/shroff/phylum/server/internal/storage"
)

const maxImageSizeNoPreview = 256 * 1024

var quality uint8
var dir string
var tmp string

func Initialize(cfg Config) error {
	quality = cfg.Quality

	if filepath.IsAbs(cfg.Dir) {
		dir = cfg.Dir
	} else {
		dir = filepath.Join(storage.Root, cfg.Dir)
	}
	tmp = filepath.Join(dir, "tmp")

	if err := os.MkdirAll(tmp, 0o700); err != nil {
		return errors.New("failed to create img directory: " + err.Error())
	}

	return nil
}

func mkdirs(name string, res Res) error {
	return os.MkdirAll(filepath.Join(dir, params[res].dir, name[len(name)-2:]), 0o700)
}

func path(name string, res Res) string {
	return filepath.Join(dir, params[res].dir, name[len(name)-2:], name[:len(name)-2]+".webp")
}

func Open(name string, res Res) (io.ReadCloser, error) {
	return os.Open(path(name, res))
}

func Copy(src, dest string, imgRes Res) error {
	for res := range params {
		if imgRes&res != 0 {
			if in, err := os.Open(path(src, res)); err != nil {
				return err
			} else if err := mkdirs(dest, res); err != nil {
				return err
			} else if out, err := os.Create(path(dest, res)); err != nil {
				return err
			} else if _, err := io.Copy(out, in); err != nil {
				return err
			}
		}
	}
	return nil
}

func Delete(name string, imgRes Res) error {
	for res := range params {
		if imgRes&res != 0 {
			if err := os.Remove(path(name, res)); err != nil {
				return err
			}
		}
	}
	return nil
}
