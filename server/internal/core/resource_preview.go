package core

import (
	"errors"
	"io"
	"io/fs"
)

func (f *FileSystem) GetPreview(r Resource, versionIDStr string) (io.ReadCloser, error) {
	id := r.latestVersionInfo.ID.String()
	preview := r.latestVersionInfo.Preview
	if versionIDStr != "" {
		id = versionIDStr
		if version, err := f.GetVersion(r, versionIDStr); err != nil {
			panic(err)
		} else {
			preview = version.Preview
		}
	}
	if !preview {
		return nil, nil
	}
	if preview, err := thumber.OpenPreview(id); err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil, ErrPreviewNotFound
		}
		return nil, err
	} else {
		return preview, nil
	}
}
