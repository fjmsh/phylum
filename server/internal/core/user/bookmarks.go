package user

import (
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type Bookmark struct {
	ResourceID uuid.UUID `json:"resource_id"`
	Name       string    `json:"name"`
	Created    int64     `json:"created"`
	Deleted    bool      `json:"deleted"`
}

func (m manager) AddBookmark(u User, resource fs.Resource, name string) (Bookmark, error) {
	if name == "" {
		name = resource.Name()
	}
	if name == "" || fs.CheckNameInvalid(name) {
		return Bookmark{}, fs.ErrResourceNameInvalid
	}
	if b, err := m.db.Queries.AddBookmark(m.ctx, db.AddBookmarkParams{
		Username:   u.Username,
		ResourceID: resource.ID(),
		Name:       name,
	}); err != nil {
		return Bookmark{}, err
	} else {
		return bookmarkFromDb(b), nil
	}
}

func (m manager) RemoveBookmark(u User, id uuid.UUID) (Bookmark, error) {
	if b, err := m.db.Queries.DeleteBookmarkByUsernameResourceID(m.ctx, db.DeleteBookmarkByUsernameResourceIDParams{Username: u.Username, ResourceID: id}); err != nil {
		return Bookmark{}, err
	} else {
		return bookmarkFromDb(b), nil
	}
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
	for i, b := range res {
		result[i] = bookmarkFromDb(b)
	}
	return result, err
}

func bookmarkFromDb(b db.Bookmark) Bookmark {
	return Bookmark{
		ResourceID: b.ResourceID,
		Name:       b.Name,
		Created:    b.Created.Time.UnixMilli(),
		Deleted:    b.Deleted.Valid,
	}
}
