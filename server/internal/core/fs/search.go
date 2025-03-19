package fs

import (
	"strings"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) Search(query string) ([]Resource, error) {
	var username pgtype.Text
	if !f.fullAccess {
		username.String = f.username
		username.Valid = true
	}
	d := db.Get()
	if res, err := d.Search(f.ctx, db.SearchParams{Search: strings.ToLower(query), Username: username}); err != nil {
		return nil, err
	} else {
		h := make([]Resource, len(res))
		for i, r := range res {
			h[i] = ResourceFromDB(r)
		}
		return h, nil
	}
}
