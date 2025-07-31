package thumbs

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
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
	"json":  true,
	"yaml":  true,
	"toml":  true,
	"x-sh":  true,
	"x-sql": true,
	"xml":   true,
}
var applicationImageTypes = map[string]bool{
	"pdf":        true,
	"postscript": true,
}

var applicationDocumentTypes = map[string]bool{
	"msword":                              true,
	"vnd.ms-excel":                        true,
	"vnd.ms-powerpoint":                   true,
	"vnd.oasis.opendocument.presentation": true,
	"vnd.oasis.opendocument.spreadsheet":  true,
	"vnd.oasis.opendocument.text":         true,
	"vnd.openxmlformats-officedocument.presentationml.presentation": true,
	"vnd.openxmlformats-officedocument.spreadsheetml.sheet":         true,
	"vnd.openxmlformats-officedocument.wordprocessingml.document":   true,
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
		if _, ok := applicationImageTypes[subType]; ok {
			return true, t.createImageThumbnail(path, output)
		}
		if _, ok := applicationTextTypes[subType]; ok {
			return true, t.createTextThumbnail(path, output)
		}
		if strings.HasSuffix("+json", subType) || strings.HasSuffix("+xml", subType) {
			return true, t.createTextThumbnail(path, output)
		}
		if _, ok := applicationDocumentTypes[subType]; ok {
			return true, t.createDocumentThumbnail(path, output)
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
	return t.createThumbnailLibreOffice(input, output, true)
}

func (t *Thumber) createDocumentThumbnail(input, output string) error {
	return t.createThumbnailLibreOffice(input, output, false)
}

func (t *Thumber) createThumbnailLibreOffice(input, output string, text bool) error {
	args := []string{
		"--headless",
		"--convert-to",
		"webp",
		"--outdir",
		t.dir,
		input,
	}
	if text {
		args = slices.Insert(args, 1, "--infilter=\"Text (encoded):UTF8,LF,Droid Sans,en-US\"")
	}

	cmd := exec.Command("soffice", args...)

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
