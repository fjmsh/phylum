package img

import (
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/storage"
)

const maxImageSizeNoPreview = 1024 * 1024

type Imgr struct {
	cfg Config
	dir string
	tmp string
}

func New(cfg Config) (*Imgr, error) {
	g := &Imgr{
		cfg: cfg,
	}

	if filepath.IsAbs(cfg.Dir) {
		g.dir = cfg.Dir
	} else {
		g.dir = filepath.Join(storage.Root, cfg.Dir)
	}
	g.tmp = filepath.Join(g.dir, "tmp")

	if err := os.MkdirAll(g.tmp, 0o700); err != nil {
		return nil, errors.New("failed to create img directory: " + err.Error())
	}

	return g, nil
}

func (g *Imgr) Open(id string, res Res) (io.ReadCloser, error) {
	return os.Open(filepath.Join(g.dir, id) + "-" + resSuffixes[res] + ".webp")
}

func (g *Imgr) Generate(path, mimeType string) (int8, error) {
	if imageType, ok := strings.CutPrefix(mimeType, "image/"); ok {
		if _, ok := imageTypes[imageType]; ok {
			return g.processImage(path)
		}
	}

	if ok := strings.HasPrefix(mimeType, "text/"); ok {
		return g.processText(path)
	}
	if subType, ok := strings.CutPrefix(mimeType, "application/"); ok {
		if _, ok := applicationImageTypes[subType]; ok {
			return g.processImage(path)
		}
		if _, ok := applicationTextTypes[subType]; ok {
			return g.processText(path)
		}
		if strings.HasSuffix("+json", subType) || strings.HasSuffix("+xml", subType) {
			return g.processText(path)
		}
		if _, ok := applicationDocumentTypes[subType]; ok {
			return g.processDocument(path)
		}
	}
	return 0, nil
}

// processImage generates preview + thumbnail for images (and PDF).
// Preview is only generated if the image size is larger than 1M
func (g *Imgr) processImage(input string) (int8, error) {
	var generated Res
	stat, err := os.Stat(input)
	if err != nil {
		return 0, errors.New("failed to find input image: " + err.Error())
	}
	base := filepath.Base(input)
	src := input
	if stat.Size() > maxImageSizeNoPreview {
		if o, err := resizeVips(src, g.dir, base, g.cfg.Quality, ResLarge); err != nil {
			return 0, err
		} else {
			src = o
		}
		generated |= ResLarge
	}

	if _, err := resizeVips(src, g.dir, base, g.cfg.Quality, ResThumbnail); err != nil {
		return 0, err
	}
	generated |= ResThumbnail
	return generated, nil
}

// Generate thumbnail only for text using.
// A temporary document preview must be generated and then resized down
func (g *Imgr) processText(input string) (int8, error) {
	if err := generateTextPreview(input, g.tmp); err != nil {
		return 0, err
	}
	// No need to keep the full generated preview since we'll render
	// the text directly on the client using file contents
	base := filepath.Base(input)
	src := filepath.Join(g.tmp, base+".webp")
	defer os.Remove(src)

	if _, err := resizeVips(src, g.dir, base, g.cfg.Quality, ResThumbnail); err != nil {
		return 0, err
	}
	return ResThumbnail, nil
}

// Generate preview and thumbnail for office documents.
func (g *Imgr) processDocument(input string) (int8, error) {
	if err := generateDocumentPreview(input, g.dir); err != nil {
		return 0, err
	}
	base := filepath.Base(input)
	out := filepath.Join(g.dir, base+".webp")
	src := filepath.Join(g.dir, base+"-"+resSuffixes[ResLarge]+".webp")
	if err := os.Rename(out, src); err != nil {
		return 0, errors.New("failed to rename document preview: " + err.Error())
	}

	if _, err := resizeVips(src, g.dir, base, g.cfg.Quality, ResThumbnail); err != nil {
		return 0, err
	}
	return ResLarge | ResThumbnail, nil
}
