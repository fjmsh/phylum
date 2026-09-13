package img

import (
	"errors"

	"github.com/davidbyttow/govips/v2/vips"
	"github.com/raitucarp/epub"
)

func processEpub(name, in string) (Res, error) {
	if r, err := epub.OpenReader(in); err != nil {
		return 0, err
	} else if cover := r.Cover(); cover == nil {
		return 0, nil
	} else if img, err := vips.NewImageFromGoImage(*cover); err != nil {
		return 0, errors.New("failed to create vips image from epub cover")
	} else {
		defer img.Close()
		return ResAll, scaleAndSaveImages(img, name, ResAll)
	}
}
