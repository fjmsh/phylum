package user

import (
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type Bookmark struct {
	ResourceID uuid.UUID  `json:"resource_id"`
	Name       string     `json:"name"`
	Deleted    *time.Time `json:"deleted"`
}

func (m manager) AddBookmark(u User, resource fs.Resource, name string) error {
	if name == "" {
		name = resource.Name()
	}
	if name == "" || fs.CheckNameInvalid(name) {
		return fs.ErrResourceNameInvalid
	}
	return m.db.Queries.AddBookmark(m.ctx, db.AddBookmarkParams{
		Username:   u.Username,
		ResourceID: resource.ID(),
		Name:       name,
	})
}

func (m manager) RemoveBookmark(u User, id uuid.UUID) error {
	return m.db.Queries.DeleteBookmarkByUsernameResourceID(m.ctx, db.DeleteBookmarkByUsernameResourceIDParams{Username: u.Username, ResourceID: id})
}

func (m manager) ListBookmarks(u User, since *time.Time) ([]Bookmark, error) {
	s := pgtype.Timestamp{
		Valid: true,
	}
	if since != nil {
		s.Time = *since
	}
	// TODO: #permissions This doesn't take permissions into account. is this okay?
	res, err := m.db.Queries.ListBookmarks(m.ctx, db.ListBookmarksParams{Username: u.Username, Since: s})
	if err != nil {
		return nil, err
	}

	result := make([]Bookmark, len(res))
	for i, r := range res {
		var deleted *time.Time
		if r.Deleted.Valid {
			deleted = &r.Deleted.Time
		}
		result[i] = Bookmark{
			ResourceID: r.ResourceID,
			Name:       r.Name,
			Deleted:    deleted,
		}
	}
	return result, err
}
