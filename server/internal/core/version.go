package core

import (
	"errors"
	"io"

	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
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

func scanVersion(row pgx.CollectableRow) (Version, error) {
	var v Version
	var created pgtype.Timestamp
	var deleted pgtype.Timestamp
	err := row.Scan(
		&v.ID,
		&created,
		&deleted,
		&v.Size,
		&v.MimeType,
		&v.SHA256,
		&v.Storage,
	)
	v.Created = int(created.Time.Unix())
	if deleted.Valid {
		v.Deleted = int(deleted.Time.Unix())
	}
	return v, err
}

func (v Version) OpenRead(start, length int) (io.ReadCloser, error) {
	if v.Storage == "" {
		return nil, errors.New("unknown storage backend")
	}
	if b, err := storage.GetBackend(v.Storage); err != nil {
		return nil, errors.New("failed to read " + v.ID.String() + ": " + err.Error())
	} else {
		return b.OpenRead(v.ID.String(), start, length)
	}
}
