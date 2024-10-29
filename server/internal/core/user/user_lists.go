package user

import (
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func (m manager) SharedResources(u User) ([]fs.Resource, error) {
	// TODO: #permissions This doesn't take permissions into account. is this okay?
	res, err := m.db.Queries.SharedResources(m.ctx, db.SharedResourcesParams{Username: u.Username, UserHome: u.Home})
	if err != nil {
		return nil, err
	}

	result := make([]fs.Resource, len(res))
	for i, r := range res {
		result[i] = resourceFromDB(r)
	}
	return result, err
}

func (m manager) AddBookmark(u User, resource fs.Resource) error {
	return m.db.Queries.AddBookmark(m.ctx, db.AddBookmarkParams{Username: u.Username, ID: resource.ID})
}

func (m manager) RemoveBookmark(u User, id uuid.UUID) error {
	return m.db.Queries.RemoveBookmark(m.ctx, db.RemoveBookmarkParams{Username: u.Username, ID: id})
}

func (m manager) Bookmarks(u User) ([]fs.Resource, error) {
	// TODO: #permissions This doesn't take permissions into account. is this okay?
	res, err := m.db.Queries.ListBookmarks(m.ctx, u.Username)
	if err != nil {
		return nil, err
	}

	result := make([]fs.Resource, len(res))
	for i, r := range res {
		result[i] = resourceFromDB(r)
	}
	return result, err
}

func resourceFromDB(r db.Resource) fs.Resource {
	var deleted *time.Time
	if r.Deleted.Valid {
		deleted = &r.Deleted.Time
	}
	return fs.Resource{
		ID:            r.ID,
		ParentID:      r.Parent,
		Name:          r.Name,
		Created:       r.Created.Time,
		Modified:      r.Modified.Time,
		Deleted:       deleted,
		Dir:           r.Dir,
		ContentSize:   r.ContentSize,
		ContentType:   r.ContentType,
		ContentSHA256: r.ContentSha256,
		Permissions:   string(r.Permissions),
		// Not Needed
		// f:                    f,
		// Path:                 "",
		// UserPermissions:      0,
		// InheritedPermissions: "",

	}
}
