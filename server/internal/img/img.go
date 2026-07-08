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

func Open(name string, res Res) (io.ReadCloser, error) {
	return os.Open(filepath.Join(dir, name) + "-" + params[res].suffix + ".webp")
}

func Copy(src, dest string, imgRes Res) error {
	for res, p := range params {
		if imgRes&res != 0 {
			if in, err := os.Open(filepath.Join(dir, src) + "-" + p.suffix + ".webp"); err != nil {
				return err
			} else if out, err := os.Create(filepath.Join(dir, dest) + "-" + p.suffix + ".webp"); err != nil {
				return err
			} else if _, err := io.Copy(out, in); err != nil {
				return err
			}
		}
	}
	return nil
}

func Delete(name string, imgRes Res) error {
	for res, p := range params {
		if imgRes&res != 0 {
			if err := os.Remove(filepath.Join(dir, name) + "-" + p.suffix + ".webp"); err != nil {
				return err
			}
		}
	}
	return nil
}
