package user

import (
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func (m manager) GetSharedResources(u User) ([]fs.Resource, error) {
	// TODO: This doesn't take permissions into account. is this okay?
	res, err := m.db.Queries.SharedResources(m.ctx, db.SharedResourcesParams{Username: u.Username, UserHome: u.Home})
	if err != nil {
		return nil, err
	}

	result := make([]fs.Resource, len(res))
	for i, r := range res {
		result[i] = fs.ResourceFromDB(r, 0, "", "")
	}
	return result, err
}

func (m manager) AddBookmark(u User, id uuid.UUID) error {
	return m.db.Queries.AddBookmark(m.ctx, db.AddBookmarkParams{Username: u.Username, ID: id})
}

func (m manager) ListBookmarks(u User) ([]fs.Resource, error) {
	res, err := m.db.Queries.ListBookmarks(m.ctx, u.Username)
	if err != nil {
		return nil, err
	}

	result := make([]fs.Resource, len(res))
	for i, r := range res {
		result[i] = fs.ResourceFromDB(r, 0, "", "")
	}
	return result, err
}
