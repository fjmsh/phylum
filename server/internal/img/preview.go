package img

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

type Res = int8

const (
	ResThumbnail Res = 1
	ResLarge     Res = 2
)

type Imgr struct {
	cfg Config
	dir string
}

// Text - No preview  +Thumbnail
// Image - Preview(vips) + Thumbnail
// Video - Preview(ffmpeg) + Thumbnail
// Document - Preview (libreoffice) + Thumbnail
func New(cfg Config) (*Imgr, error) {
	g := &Imgr{
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

func (g *Imgr) Open(id string, res Res) (io.ReadCloser, error) {
	return os.Open(filepath.Join(g.dir, id))
}

func (g *Imgr) Generate(path, mimeType string) (bool, error) {
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

func (g *Imgr) createImagePreview(input, output string) error {
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

func (g *Imgr) generateTextPreview(input, output string) error {
	return g.generateLibreOfficePreview(input, output, true)
}

func (g *Imgr) generateDocumentPreview(input, output string) error {
	return g.generateLibreOfficePreview(input, output, false)
}

func (g *Imgr) generateLibreOfficePreview(input, output string, text bool) error {
	args := []string{
		"--headless",
		"--convert-to",
		"webp",
		"--outdir",
		g.dir,
		input,
	}
	if text {
		args = slices.Insert(args, 1, "--infilter=\"Text (encoded):UTF8,LF,Noto Sans,en-US\"")
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
