package core

import (
	"errors"
	"io"
	"io/fs"

	"codeberg.org/shroff/phylum/server/internal/img"
)

func (f *FileSystem) GetImg(r Resource, versionIDStr string, resolution img.Res) (io.ReadCloser, error) {
	id := r.latestVersionInfo.ID.String()
	imgres := r.latestVersionInfo.ImgRes
	if versionIDStr != "" {
		id = versionIDStr
		if version, err := f.GetVersion(r, versionIDStr); err != nil {
			panic(err)
		} else {
			imgres = version.ImgRes
		}
	}
	if resolution&imgres == 0 {
		return nil, nil
	}
	if r, err := img.Open(id, resolution); err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil, ErrPreviewNotFound
		}
		return nil, err
	} else {
		return r, nil
	}
}
