package fs

import (
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) ListDeleted(n int) ([]Resource, error) {
	var username pgtype.Text
	if !f.fullAccess {
		username.String = f.username
		username.Valid = true
	}

	if res, err := f.db.ListDeleted(f.ctx, db.ListDeletedParams{Username: username, N: int32(n)}); err != nil {
		return nil, err
	} else {
		deleted := make([]Resource, len(res))
		for i, r := range res {
			deleted[i] = ResourceFromDB(r)
		}
		return deleted, nil
	}
}
