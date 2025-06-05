package core

import (
	"errors"
	"io"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/storage"
)

// VersionInfo represents a single version of a resource
// json tags are needed for unmarshalling the json object in sql queries
type VersionInfo struct {
	ID       uuid.UUID `json:"id"`
	Created  int       `json:"created"`
	Deleted  int       `json:"deleted"`
	Size     int64     `json:"size"`
	MimeType string    `json:"mime_type"`
	SHA256   string    `json:"sha256"`
}

type Version struct {
	VersionInfo
	Storage string
}

func (v Version) OpenRead(start, length int) (io.ReadCloser, error) {
	if v.Storage == "" {
		return nil, errors.New("unknown storage backend")
	}
	if b := storage.GetBackend(v.Storage); b == nil {
		return nil, errors.New("storage backend not found: " + v.Storage)
	} else {
		return b.OpenRead(v.ID.String(), start, length)
	}
}
