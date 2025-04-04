package fs

import (
	"github.com/google/uuid"
)

func (f filesystem) updateResourceModified(id uuid.UUID) error {
	const q = "UPDATE resources SET modified = NOW() WHERE id = $1"
	_, err := f.db.Exec(q, id)
	return err
}
func (f filesystem) updateResourceContents(id uuid.UUID, contentLength int, contentType, contentSHA256 string) error {
	const q = `UPDATE resources SET
    content_length = $2::INTEGER,
    content_type = $3::TEXT, 
    content_sha256 = $4::TEXT,
    modified = NOW()
WHERE id = $1::UUID
`
	_, err := f.db.Exec(q, id, contentLength, contentType, contentSHA256)
	return err
}
