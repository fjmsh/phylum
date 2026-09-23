package img

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
)

var m = sync.Mutex{}

// Generate preview and thumbnail for office documents.
func processDocument(name, in string) (Res, error) {
	if err := exportLibreOffice(in, dir, false); err != nil {
		return 0, err
	}
	if err := mkdirs(name, ResLarge); err != nil {
		return 0, err
	}
	out := filepath.Join(dir, filepath.Base(in)+".webp")
	preview := path(name, ResLarge)
	if err := os.Rename(out, preview); err != nil {
		return 0, errors.New("failed to rename document preview: " + err.Error())
	}

	if err := generateThumbnailFromFile(preview, name); err != nil {
		os.Remove(preview)
		return 0, errors.New("failed to generate thumbnail: " + err.Error())
	}
	return ResLarge | ResThumbnail, nil
}

// Generate thumbnail only for text using LibreOffice
// A temporary document preview must be generated and then resized down
func processText(name, in string) (Res, error) {
	if err := exportLibreOffice(in, tmp, true); err != nil {
		return 0, err
	}
	// No need to keep the full generated preview since we'll render
	// the text directly on the client using file contents
	preview := filepath.Join(tmp, filepath.Base(in)+".webp")
	defer os.Remove(preview)

	if err := generateThumbnailFromFile(preview, name); err != nil {
		return 0, errors.New("failed to generate thumbnail: " + err.Error())
	}
	return ResThumbnail, nil
}

func exportLibreOffice(input, outdir string, text bool) error {
	args := []string{
		"--headless",
		"--convert-to",
	}
	if text {
		args = append(args,
			"webp:writer_webp_Export",
			"--infilter=\"Text (encoded):UTF8,LF,Noto Sans,en-US\"", // TOOO: change font? locale?
		)
	} else {
		args = append(args, "--webp")
	}
	args = append(args,
		"--outdir",
		outdir,
		input)

	cmd := exec.Command("soffice", args...)

	m.Lock()
	if err := cmd.Run(); err != nil {
		return errors.New("failed to generate preview using LibreOffice: " + err.Error())
	}
	m.Unlock()
	return nil
}
