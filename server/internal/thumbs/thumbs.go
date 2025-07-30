package thumbs

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
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

var applicationTextTypes = map[string]bool{
	"json": true,
	"yaml": true,
	"toml": true,
}

func NewThumber(cfg Config) (*Thumber, error) {
	t := &Thumber{
		cfg: cfg,
	}

	if filepath.IsAbs(cfg.Dir) {
		t.dir = cfg.Dir
	} else {
		t.dir = filepath.Join(storage.Root, cfg.Dir)
	}
	if err := os.MkdirAll(t.dir, 0o700); err != nil {
		return nil, errors.New("failed to create thumbnail directory: " + err.Error())
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
	if ok := strings.HasPrefix(mimeType, "text/"); ok {
		return true, t.createTextThumbnail(path, output)
	}
	if subType, ok := strings.CutPrefix(mimeType, "application/"); ok {
		if _, ok := applicationTextTypes[subType]; ok {
			return true, t.createTextThumbnail(path, output)
		}
	}
	return false, nil
}

func (t *Thumber) createImageThumbnail(input, output string) error {
	outputWithFormat := output + ".webp"
	outputWithFormatQuality := fmt.Sprintf("%s[Q=%d]", outputWithFormat, t.cfg.Quality)
	cmd := exec.Command(
		"vips",
		"thumbnail",
		input,
		outputWithFormatQuality,
		"240",
		"--size",
		"down",
	)
	err := cmd.Run()
	if err != nil {
		return errors.New("failed to create image thumbnail: " + err.Error())
	}
	return os.Rename(outputWithFormat, output)
}

func (t *Thumber) createTextThumbnail(input, output string) error {
	cmd := exec.Command(
		"soffice",
		"--headless",
		"--infilter=\"Text (encoded):UTF8,LF,Droid Sans,en-US\"",
		"--convert-to",
		"webp:writer_webp_Export",
		"--outdir",
		t.dir,
		input,
	)

	if err := cmd.Run(); err != nil {
		return errors.New("failed to generate text thumbnail: " + err.Error())
	}

	tempOutput := filepath.Join(t.dir, filepath.Base(input+".webp"))
	src := tempOutput + ".orig"
	if err := os.Rename(tempOutput, src); err != nil {
		return errors.New("failed to rename text thumbnail: " + err.Error())
	}
	if err := t.createImageThumbnail(src, output); err != nil {
		return errors.New("failed to resize text thumbnail: " + err.Error())
	}
	return os.Remove(src)
}
