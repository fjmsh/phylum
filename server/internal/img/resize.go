package img

import (
	"errors"
	"fmt"
	"os/exec"
	"path/filepath"
	"strconv"
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
