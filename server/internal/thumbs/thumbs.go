package thumbs

import (
	"errors"
)

type Thumber struct {
	outputFormat string
	quality      int
	size         int
}

func NewThumber(cfg Config) (*Thumber, error) {
	t := new(Thumber)
	if cfg.Format == "jpeg" || cfg.Format == "webp" {
		t.outputFormat = "." + cfg.Format
		t.size = int(cfg.Size)
	} else {
		return nil, errors.New("unrecognized output format: " + cfg.Format)
	}

	return t, nil
}

func (t *Thumber) Generate(path, mimeType string) (bool, error) {
	return false, nil
}
