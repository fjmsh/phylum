package user

import (
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func (m manager) SharedResources(u User) ([]fs.ResourceInfo, error) {
	res, err := m.db.Queries.SharedResources(m.ctx, db.SharedResourcesParams{Username: u.Username, UserHome: u.Home})
	if err != nil {
		return nil, err
	}

	result := make([]fs.ResourceInfo, len(res))
	for i, r := range res {
		result[i] = fs.ResourceInfoFromDBResource(r)
	}
	return result, err
}
