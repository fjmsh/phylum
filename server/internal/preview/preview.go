package preview

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/storage"
)

type Generator struct {
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

func NewGenerator(cfg Config) (*Generator, error) {
	g := &Generator{
		cfg: cfg,
	}

	if filepath.IsAbs(cfg.Dir) {
		g.dir = cfg.Dir
	} else {
		g.dir = filepath.Join(storage.Root, cfg.Dir)
	}
	if err := os.MkdirAll(g.dir, 0o700); err != nil {
		return nil, errors.New("failed to create thumbnail directory: " + err.Error())
	}

	return g, nil
}

func (g *Generator) OpenPreview(id string) (io.ReadCloser, error) {
	return os.Open(filepath.Join(g.dir, id))
}

func (g *Generator) GeneratePreview(path, mimeType string) (bool, error) {
	output := filepath.Join(g.dir, filepath.Base(path))
	if imageType, ok := strings.CutPrefix(mimeType, "image/"); ok {
		if _, ok := imageTypes[imageType]; ok {
			return true, g.createImagePreview(path, output)
		}
	}
	if ok := strings.HasPrefix(mimeType, "text/"); ok {
		return true, g.generateTextPreview(path, output)
	}
	if subType, ok := strings.CutPrefix(mimeType, "application/"); ok {
		if _, ok := applicationImageTypes[subType]; ok {
			return true, g.createImagePreview(path, output)
		}
		if _, ok := applicationTextTypes[subType]; ok {
			return true, g.generateTextPreview(path, output)
		}
		if strings.HasSuffix("+json", subType) || strings.HasSuffix("+xml", subType) {
			return true, g.generateTextPreview(path, output)
		}
		if _, ok := applicationDocumentTypes[subType]; ok {
			return true, g.generateDocumentPreview(path, output)
		}
	}
	return false, nil
}

func (g *Generator) createImagePreview(input, output string) error {
	outputWithFormat := output + ".webp"
	outputWithFormatQuality := fmt.Sprintf("%s[Q=%d]", outputWithFormat, g.cfg.Quality)
	cmd := exec.Command(
		"vips",
		"thumbnail",
		input,
		outputWithFormatQuality,
		"480",
		"--size",
		"down",
	)
	err := cmd.Run()
	if err != nil {
		return errors.New("failed to create image preview: " + err.Error())
	}
	return os.Rename(outputWithFormat, output)
}

func (g *Generator) generateTextPreview(input, output string) error {
	return g.generateLibreOfficePreview(input, output, true)
}

func (g *Generator) generateDocumentPreview(input, output string) error {
	return g.generateLibreOfficePreview(input, output, false)
}

func (g *Generator) generateLibreOfficePreview(input, output string, text bool) error {
	args := []string{
		"--headless",
		"--convert-to",
		"webp",
		"--outdir",
		g.dir,
		input,
	}
	if text {
		args = slices.Insert(args, 1, "--infilter=\"Text (encoded):UTF8,LF,Droid Sans,en-US\"")
	}

	cmd := exec.Command("soffice", args...)

	if err := cmd.Run(); err != nil {
		return errors.New("failed to generate LibreOffice preview: " + err.Error())
	}

	tempOutput := filepath.Join(g.dir, filepath.Base(input+".webp"))
	src := tempOutput + ".orig"
	if err := os.Rename(tempOutput, src); err != nil {
		return errors.New("failed to rename LibreOffice preview: " + err.Error())
	}
	if err := g.createImagePreview(src, output); err != nil {
		return errors.New("failed to resize LibreOffice preview: " + err.Error())
	}
	return os.Remove(src)
}
