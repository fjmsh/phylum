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
	size := resolutions[ResLarge]
	output := filepath.Join(outdir, basename+"-"+resSuffixes[ResLarge]+".webp")
	if img, err := vips.LoadImageFromFile(input, vips.NewImportParams()); err != nil {
		return "", errors.New("failed to load image: " + err.Error())
	} else {
		defer img.Close()
		if err := img.ThumbnailWithSize(int(size), int(size), vips.InterestingNone, vips.SizeDown); err != nil {
			return "", errors.New("failed to create image preiew: " + err.Error())
		} else if b, _, err := img.ExportWebp(&vips.WebpExportParams{Quality: int(quality)}); err != nil {
			return "", errors.New("failed to export image preview to webp: " + err.Error())
		} else if err := os.WriteFile(output, b, 0600); err != nil {
			return "", errors.New("failed to write image preview file: " + err.Error())
		} else {
			return output, nil
		}
	}
}

func generateThumbnail(input, outdir, basename string, quality uint8) (string, error) {
	size := resolutions[ResThumbnail]
	output := filepath.Join(outdir, basename+"-"+resSuffixes[ResThumbnail]+".webp")
	if img, err := vips.LoadImageFromFile(input, vips.NewImportParams()); err != nil {
		return "", errors.New("failed to load image: " + err.Error())
	} else {
		defer img.Close()
		if err := img.Thumbnail(int(size), int(size), vips.InterestingAttention); err != nil {
			return "", errors.New("failed to create thumbnail: " + err.Error())
		} else if b, _, err := img.ExportWebp(&vips.WebpExportParams{Quality: int(quality)}); err != nil {
			return "", errors.New("failed to export thumbnail to webp: " + err.Error())
		} else if err := os.WriteFile(output, b, 0600); err != nil {
			return "", errors.New("failed to write thumbnail file: " + err.Error())
		} else {
			img.Close()
			return output, nil
		}
	}
}
