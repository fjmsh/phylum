package fs

import "github.com/google/uuid"

func (f filesystem) updateResourceModified(id uuid.UUID) error {
	const q = "UPDATE resources SET modified = NOW() WHERE id = $1"
	_, err := f.db.Exec(f.ctx, q, id)
	return err
}
