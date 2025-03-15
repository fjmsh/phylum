package user

import (
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func (m manager) SharedResources(u User) ([]fs.Resource, error) {
	res, err := m.db.Queries.SharedResources(m.ctx, db.SharedResourcesParams{Username: u.Username, UserHome: u.Home})
	if err != nil {
		return nil, err
	}

	result := make([]fs.Resource, len(res))
	for i, r := range res {
		result[i] = fs.ResourceFromDB(r)
	}
	return result, err
}
