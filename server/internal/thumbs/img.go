package thumbs

import (
	"fmt"
	"os/exec"
	"strconv"
)

func (t *Thumber) ResizeImage(input, out string) error {
	return exec.Command("vips", "thumbnail", input, fmt.Sprintf("%s.%s[Q=%d]", out, t.outputFormat, t.quality), strconv.Itoa(t.size), "--size", "down").Run()
}
