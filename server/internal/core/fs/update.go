package fs

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (f filesystem) updateResourceModified(id uuid.UUID) error {
	const q = "UPDATE resources SET modified = NOW() WHERE id = $1"
	_, err := f.db.Exec(q, id)
	return err
}

func (f filesystem) createResourceVersion(id, versionID uuid.UUID, size int64, mimeType, sha256 string) error {
	const q = `INSERT INTO resource_versions(id, resource_id, size, mime_type, sha256, storage)
	VALUES (@version_id::UUID, @resource_id::UUID, @size::INT, @mime_type::TEXT, @sha256::TEXT, @storage::TEXT)`

	args := pgx.NamedArgs{
		"resource_id": id,
		"version_id":  versionID,
		"size":        size,
		"mime_type":   mimeType,
		"sha256":      sha256,
		"storage":     "_",
	}
	_, err := f.db.Exec(q, args)
	return err
}
