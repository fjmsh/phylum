package core

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (f filesystem) GetVersion(r Resource, versionID uuid.UUID) (Version, error) {
	if versionID == uuid.Nil {
		versionID = r.latestVersionInfo.ID
	}

	const q = `SELECT id, created, size, mime_type, sha256, storage FROM resource_versions
WHERE resource_id = $1::UUID
AND id = $2::UUID
AND DELETED IS NULL`

	row := f.db.QueryRow(q, r.id, versionID)
	var v Version
	var created time.Time
	err := row.Scan(&v.ID, &created, &v.Size, &v.MimeType, &v.SHA256, &v.Storage)
	if err != nil {
		if Is(err, pgx.ErrNoRows) {
			return v, ErrVersionNotFound
		} else {
			return v, errors.New("failed to get resource version: " + err.Error())
		}
	}
	v.Created = int(created.Unix())
	return v, nil
}

func (f filesystem) GetAllVersions(r Resource) ([]Version, error) {
	const q = `SELECT id, created, deleted, size, mime_type, sha256, storage FROM resource_versions
WHERE resource_id = $1::UUID
ORDER BY created DESC`
	if rows, err := f.db.Query(q, r.id); err != nil {
		return nil, errors.New("failed to get resource versions: " + err.Error())
	} else {
		return pgx.CollectRows(rows, scanVersion)
	}
}
