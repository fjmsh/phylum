package img

import (
	"errors"
	"os"
	"path/filepath"

	"github.com/davidbyttow/govips/v2/vips"
)

type Res = uint8

const (
	ResThumbnail Res = 1
	ResLarge     Res = 2
)

var resSuffixes = map[Res]string{
	ResThumbnail: "t",
	ResLarge:     "l",
}

var resolutions = map[Res]int{
	ResThumbnail: 240,
	ResLarge:     1200,
}

func generateImagePreview(input, outdir, basename string, quality uint8) (string, error) {
	if img, err := vips.LoadImageFromFile(input, vips.NewImportParams()); err != nil {
		return "", errors.New("failed to load image: " + err.Error())
	} else {
		defer img.Close()
		return scaleAndSaveImage(img, outdir, basename, quality, ResLarge, vips.InterestingNone)
	}
}

func generateThumbnail(input, outdir, basename string, quality uint8) (string, error) {
	// density := vips.IntParameter{}
	// density.Set(300)
	if img, err := vips.LoadImageFromFile(input, vips.NewImportParams()); err != nil {
		return "", errors.New("failed to load image: " + err.Error())
	} else {
		defer img.Close()
		return scaleAndSaveImage(img, outdir, basename, quality, ResThumbnail, vips.InterestingAttention)
	}
}

func scaleAndSaveImage(img *vips.ImageRef, outdir, basename string, quality uint8, res Res, interesting vips.Interesting) (string, error) {
	width := resolutions[res]
	height := width * img.Height() / img.Width()
	output := filepath.Join(outdir, basename+"-"+resSuffixes[res]+".webp")
	if err := img.Thumbnail(width, height, interesting); err != nil {
		return "", errors.New("failed to create image preiew: " + err.Error())
	} else {
		if b, _, err := img.ExportWebp(&vips.WebpExportParams{Quality: int(quality)}); err != nil {
			return "", errors.New("failed to export image preview to webp: " + err.Error())
		} else if err := os.WriteFile(output, b, 0600); err != nil {
			return "", errors.New("failed to write image preview file: " + err.Error())
		} else {
			return output, nil
		}
	}
}
