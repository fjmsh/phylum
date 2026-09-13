package img

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
)

// Generate preview and thumbnail for office documents.
func processDocument(name, path string) (Res, error) {
	if err := exportLibreOffice(path, dir, false); err != nil {
		return 0, err
	}
	out := filepath.Join(dir, filepath.Base(path)+".webp")
	preview := filepath.Join(dir, name+"-"+params[ResLarge].suffix+".webp")
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
func processText(name, path string) (Res, error) {
	if err := exportLibreOffice(path, tmp, true); err != nil {
		return 0, err
	}
	// No need to keep the full generated preview since we'll render
	// the text directly on the client using file contents
	preview := filepath.Join(tmp, filepath.Base(path)+".webp")
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
			"--outdir")
	} else {
		args = append(args, "--webp")
	}
	args = append(args,
		"--outdir",
		outdir,
		input)

	cmd := exec.Command("soffice", args...)

	if err := cmd.Run(); err != nil {
		return errors.New("failed to generate preview using LibreOffice: " + err.Error())
	}
	return nil
}
