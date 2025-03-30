package user

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type Bookmark struct {
	ResourceID uuid.UUID `json:"resource_id"`
	Name       string    `json:"name"`
	Dir        bool      `json:"dir"`
	Created    int64     `json:"created"`
}

func scanBookmark(row pgx.CollectableRow) (Bookmark, error) {
	var p Bookmark
	if err := row.Scan(
		&p.ResourceID,
		&p.Name,
		&p.Dir,
		&p.Created,
	); err != nil {
		return Bookmark{}, err
	}
	return p, nil
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
		Dir:        resource.Dir(),
	}); err != nil {
		return Bookmark{}, err
	} else {
		return bookmarkFromDb(b), nil
	}
}

func (m manager) RemoveBookmark(u User, id uuid.UUID) error {
	const q = "DELETE FROM bookmarks WHERE username = $1::TEXT AND resource_id = $2::UUID"
	_, err := m.db.Exec(m.ctx, q, u.Username, id)
	return err
}

func (m manager) ListBookmarks(u User) ([]Bookmark, error) {
	const q = `SELECT resource_id, name, dir, created
FROM bookmarks b
WHERE username = $1::TEXT
AND deleted IS NULL
ORDER BY modified DESC`

	if rows, err := m.db.Query(m.ctx, q, u.Username); err != nil {
		return nil, err
	} else if bookmarks, err := pgx.CollectRows(rows, scanBookmark); err != nil {
		return nil, err
	} else {
		return bookmarks, nil
	}
}

func bookmarkFromDb(b db.Bookmark) Bookmark {
	return Bookmark{
		ResourceID: b.ResourceID,
		Name:       b.Name,
		Dir:        b.Dir,
		Created:    b.Created.Time.UnixMilli(),
	}
}
