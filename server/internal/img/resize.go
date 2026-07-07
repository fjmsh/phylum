package img

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"

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

func resizeVips(input, outdir, basename string, quality uint8, size Res) (string, error) {
	output := filepath.Join(outdir, basename+"-"+resSuffixes[size]+".webp")
	cmd := exec.Command(
		"vips",
		"thumbnail",
		input,
		fmt.Sprintf("%s[Q=%d]", output, quality),
		strconv.Itoa(resolutions[size]),
		"--size",
		"down",
	)
	err := cmd.Run()
	if err != nil {
		return "", errors.New("failed to resize image using vips: " + err.Error())
	}
	return output, nil
}

func generateThumbnail(input, outdir, basename string, quality uint8) (string, error) {
	size := resolutions[ResThumbnail]
	output := filepath.Join(outdir, basename+"-"+resSuffixes[ResThumbnail]+".webp")
	if img, err := vips.LoadImageFromFile(input, vips.NewImportParams()); err != nil {
		return "", errors.New("failed to load image: " + err.Error())
	} else if err := img.Thumbnail(int(size), int(size), vips.InterestingAttention); err != nil {
		return "", errors.New("failed to create thumbnail: " + err.Error())
	} else if b, _, err := img.ExportWebp(&vips.WebpExportParams{Quality: int(quality)}); err != nil {
		return "", errors.New("failed to export to webp: " + err.Error())
	} else if err := os.WriteFile(output, b, 0600); err != nil {
		return "", errors.New("failed to write thumbnail file: " + err.Error())
	} else {
		return output, nil
	}
}
