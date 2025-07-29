package thumbs

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/storage"
)

type Thumber struct {
	dir string
	cfg Config
}

var imageTypes = map[string]bool{
	"bmp":     true,
	"gif":     true,
	"heic":    true,
	"heif":    true,
	"jpeg":    true,
	"png":     true,
	"svg+xml": true,
	"webp":    true,
	"x-icon":  true,
}

func NewThumber(cfg Config) (*Thumber, error) {
	t := &Thumber{
		cfg: cfg,
	}
	if cfg.Format != "jpeg" && cfg.Format != "webp" {
		return nil, errors.New("unrecognized output format: " + cfg.Format)
	}

	if !filepath.IsAbs(cfg.Dir) {
		t.dir = filepath.Join(storage.Root, cfg.Dir)
		if err := os.MkdirAll(t.dir, 0o700); err != nil {
			return nil, errors.New("failed to create thumbnail directory: " + err.Error())
		}
	}

	return t, nil
}

func (t *Thumber) Generate(path, mimeType string) (bool, error) {
	output := filepath.Join(t.dir, filepath.Base(path))
	if imageType, ok := strings.CutPrefix(mimeType, "image/"); ok {
		if _, ok := imageTypes[imageType]; ok {
			return true, t.createImageThumbnail(path, output)
		}
	}
	return false, nil
}

func (t *Thumber) createImageThumbnail(input, output string) error {
	vipsFormattedOutput := fmt.Sprintf("%s.%s[Q=%d]", output, t.cfg.Format, t.cfg.Quality)
	cmd := exec.Command(
		"vips",
		"thumbnail",
		input,
		vipsFormattedOutput,
		strconv.Itoa(int(t.cfg.Size)),
		"--size",
		"down",
	)
	err := cmd.Run()
	if err != nil {
		return errors.New("failed to create image thumbnail: " + err.Error())
	}
	os.Rename(output+"."+t.cfg.Format, output)
	return nil
}
