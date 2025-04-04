package user

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
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

	const q = `INSERT INTO bookmarks(username, resource_id, name, dir)
VALUES ($1::TEXT, $2::UUID, $3::TEXT, $4::BOOLEAN)
ON CONFLICT(username, resource_id) DO UPDATE
SET
    created = CASE WHEN bookmarks.deleted IS NULL THEN CURRENT_TIMESTAMP ELSE bookmarks.created END,
    modified = CURRENT_TIMESTAMP,
    deleted = NULL,
    name = $3::TEXT
RETURNING resource_id, name, dir, created`

	if rows, err := m.db.Query(q, u.Username); err != nil {
		return Bookmark{}, err
	} else if bookmark, err := pgx.CollectExactlyOneRow(rows, scanBookmark); err != nil {
		return Bookmark{}, err
	} else {
		return bookmark, nil
	}
}

func (m manager) RemoveBookmark(u User, id uuid.UUID) error {
	const q = "DELETE FROM bookmarks WHERE username = $1::TEXT AND resource_id = $2::UUID"
	_, err := m.db.Exec(q, u.Username, id)
	return err
}

func (m manager) ListBookmarks(u User) ([]Bookmark, error) {
	const q = `SELECT resource_id, name, dir, created
FROM bookmarks b
WHERE username = $1::TEXT
AND deleted IS NULL
ORDER BY modified DESC`

	if rows, err := m.db.Query(q, u.Username); err != nil {
		return nil, err
	} else if bookmarks, err := pgx.CollectRows(rows, scanBookmark); err != nil {
		return nil, err
	} else {
		return bookmarks, nil
	}
}
