package img

import (
	"errors"
	"fmt"
	"os"

	"github.com/davidbyttow/govips/v2/vips"
)

type Res = uint8

const (
	ResThumbnail Res = 1
	ResLarge     Res = 2
	ResAll       Res = ResLarge | ResThumbnail
)

type resParams struct {
	// suffix      string
	dir         string
	width       int
	interesting vips.Interesting
}

var params = map[Res]resParams{
	ResThumbnail: {
		dir:         "thumbs",
		width:       240,
		interesting: vips.InterestingAttention,
	},
	ResLarge: {
		dir:         "previews",
		width:       1200,
		interesting: vips.InterestingNone,
	},
}

func generateThumbnailFromFile(input, basename string) error {
	if img, err := vips.LoadImageFromFile(input, vips.NewImportParams()); err != nil {
		return errors.New("failed to load image: " + err.Error())
	} else {
		defer img.Close()
		return scaleAndSaveImage(img, basename, ResThumbnail)
	}
}

func scaleAndSaveImages(img *vips.ImageRef, name string, res Res) (err error) {
	// Res is uint8
	for i := 7; i >= 0; i-- {
		r := Res(1 << uint(i))
		if res&(r) != 0 {
			if err := scaleAndSaveImage(img, name, r); err != nil {
				return fmt.Errorf("failed to save image for res %d: %s", r, err.Error())
			}
		}
	}
	return nil
}

func scaleAndSaveImage(img *vips.ImageRef, basename string, res Res) error {
	params, ok := params[res]
	if !ok {
		return fmt.Errorf("unknown image resolution: %d", res)
	}
	output := path(basename, res)

	if params.width < img.Width() {
		height := params.width * img.Height() / img.Width()
		if err := img.Thumbnail(params.width, height, params.interesting); err != nil {
			return errors.New("failed to create image preiew: " + err.Error())
		}
	}

	if b, _, err := img.ExportWebp(&vips.WebpExportParams{Quality: int(quality)}); err != nil {
		return errors.New("failed to export image preview to webp: " + err.Error())
	} else if err := mkdirs(basename, res); err != nil {
		return errors.New("failed to create directory: " + err.Error())
	} else if err := os.WriteFile(output, b, 0600); err != nil {
		return errors.New("failed to write image preview file: " + err.Error())
	} else {
		return nil
	}
}
