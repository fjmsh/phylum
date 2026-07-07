package img

import (
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/HugoSmits86/nativewebp"
	"github.com/raitucarp/epub"
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
	return os.Open(filepath.Join(dir, name) + "-" + resSuffixes[res] + ".webp")
}

func Copy(src, dest string, imgRes Res) error {
	for res, s := range resSuffixes {
		if imgRes&res != 0 {
			if in, err := os.Open(filepath.Join(dir, src) + "-" + s + ".webp"); err != nil {
				return err
			} else if out, err := os.Create(filepath.Join(dir, dest) + "-" + s + ".webp"); err != nil {
				return err
			} else if _, err := io.Copy(out, in); err != nil {
				return err
			}
		}
	}
	return nil
}

func Delete(name string, imgRes Res) error {
	for res, s := range resSuffixes {
		if imgRes&res != 0 {
			if err := os.Remove(filepath.Join(dir, name) + "-" + s + ".webp"); err != nil {
				return err
			}
		}
	}
	return nil
}

func GetGenerator(mimeType string) func(string) (uint8, error) {
	if imageType, ok := strings.CutPrefix(mimeType, "image/"); ok {
		if _, ok := imageTypes[imageType]; ok {
			return func(path string) (uint8, error) { return processImage(path, false) }
		}
	}

	if ok := strings.HasPrefix(mimeType, "text/"); ok {
		return func(path string) (uint8, error) { return processText(path) }
	}
	if subType, ok := strings.CutPrefix(mimeType, "application/"); ok {
		if fn, ok := applicationTypes[subType]; ok {
			return fn
		}

		if strings.HasSuffix("+json", subType) || strings.HasSuffix("+xml", subType) {
			return processText
		}
	}
	return nil
}

func processApplicationImage(path string) (Res, error) {
	return processImage(path, true)
}

// processImage generates preview + thumbnail for images (and PDF).
// Preview is only generated if the image size is larger than 1M
// or if forcePreview is set to true (typically for non-image formats)
// like PDF and PS
func processImage(input string, forcePreview bool) (Res, error) {
	var generated Res
	stat, err := os.Stat(input)
	if err != nil {
		return 0, errors.New("failed to find input image: " + err.Error())
	}
	base := filepath.Base(input)
	src := input
	if forcePreview || stat.Size() > maxImageSizeNoPreview {
		if o, err := generateImagePreview(src, dir, base, quality); err != nil {
			return 0, err
		} else {
			src = o
		}
		generated |= ResLarge
	}

	if _, err := generateThumbnail(src, dir, base, quality); err != nil {
		return 0, err
	}
	generated |= ResThumbnail
	return generated, nil
}

// Generate thumbnail only for text using.
// A temporary document preview must be generated and then resized down
func processText(input string) (Res, error) {
	if err := generateTextPreview(input, tmp); err != nil {
		return 0, err
	}
	// No need to keep the full generated preview since we'll render
	// the text directly on the client using file contents
	base := filepath.Base(input)
	src := filepath.Join(tmp, base+".webp")
	defer os.Remove(src)

	if _, err := generateThumbnail(src, dir, base, quality); err != nil {
		return 0, err
	}
	return ResThumbnail, nil
}

func processEpub(path string) (Res, error) {
	if r, err := epub.OpenReader(path); err != nil {
		return 0, err
	} else if cover := r.Cover(); cover == nil {
		return 0, nil
	} else {
		base := filepath.Base(path)
		large := filepath.Join(dir, base+"-"+resSuffixes[ResLarge]+".webp")
		var generated Res
		if f, err := os.Create(large); err != nil {
			return 0, err
		} else if err := nativewebp.Encode(f, *cover, nil); err != nil {
			f.Close()
			return 0, err
		} else {
			f.Close()
			generated |= ResLarge
			if _, err := generateThumbnail(large, dir, base, quality); err != nil {
				return 0, err
			}
			generated |= ResThumbnail
			return generated, nil
		}
	}
}

// Generate preview and thumbnail for office documents.
func processDocument(input string) (Res, error) {
	if err := generateDocumentPreview(input, dir); err != nil {
		return 0, err
	}
	base := filepath.Base(input)
	out := filepath.Join(dir, base+".webp")
	src := filepath.Join(dir, base+"-"+resSuffixes[ResLarge]+".webp")
	if err := os.Rename(out, src); err != nil {
		return 0, errors.New("failed to rename document preview: " + err.Error())
	}

	if _, err := generateThumbnail(src, dir, base, quality); err != nil {
		return 0, err
	}
	return ResLarge | ResThumbnail, nil
}
