package img

import (
	"errors"
	"os"
	"path/filepath"
	"strings"

	"github.com/davidbyttow/govips/v2/vips"
)

func GetGenerator(mimeType string) func(string) (uint8, error) {
	if imageType, ok := strings.CutPrefix(mimeType, "image/"); ok || otherImageTypes[mimeType] {
		return func(path string) (Res, error) {
			allowNoPreviewImage := nativeImageTypes[imageType]
			return processImage(path, !allowNoPreviewImage)
		}
	}

	if ok := strings.HasPrefix(mimeType, "text/"); ok {
		return processText
	}

	if ok := strings.HasPrefix(mimeType, "video/"); ok {
		return processAV
	}

	if ok := strings.HasPrefix(mimeType, "audio/"); ok {
		return processAV
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

// processImage generates preview + thumbnail for images (and PDF).
// Preview is only generated if the image size is larger than 1M
// or if forcePreview is set to true (typically for non-image formats)
// like PDF and PS
func processImage(path string, forceSavePreview bool) (Res, error) {
	res := ResThumbnail
	if forceSavePreview {
		res |= ResLarge
	} else if stat, err := os.Stat(path); err != nil {
		return 0, err
	} else if stat.Size() > 512*1024 {
		res |= ResLarge
	}
	if img, err := vips.LoadImageFromFile(path, vips.NewImportParams()); err != nil {
		return 0, errors.New("failed to load image file: " + err.Error())
	} else {
		defer img.Close()
		return res, scaleAndSaveImages(img, filepath.Base(path), res)
	}
}
