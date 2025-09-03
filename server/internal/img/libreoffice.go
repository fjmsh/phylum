package img

import (
	"errors"
	"os/exec"
)

func generateDocumentPreview(input, outdir string) error {
	args := []string{
		"--headless",
		"--convert-to",
		"webp",
		"--outdir",
		outdir,
		input,
	}

	cmd := exec.Command("soffice", args...)

	if err := cmd.Run(); err != nil {
		return errors.New("failed to generate LibreOffice Document preview: " + err.Error())
	}
	return nil
}

func generateTextPreview(input, outdir string) error {
	args := []string{
		"--headless",
		"--convert-to",
		"webp",
		"--infilter=\"Text (encoded):UTF8,LF,Noto Sans,en-US\"", // TOOO: change font? locale?
		"--outdir",
		outdir,
		input,
	}

	cmd := exec.Command("soffice", args...)

	if err := cmd.Run(); err != nil {
		return errors.New("failed to generate LibreOffice Text preview: " + err.Error())
	}
	return nil
}
