package core

import (
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type Bookmark struct {
	ResourceID uuid.UUID
	Name       string
	Dir        bool
	Created    time.Time
	MimeType   pgtype.Text
}

func scanBookmark(row pgx.CollectableRow) (Bookmark, error) {
	var b Bookmark
	if err := row.Scan(
		&b.ResourceID,
		&b.Name,
		&b.Dir,
		&b.Created,
		&b.MimeType,
	); err != nil {
		return Bookmark{}, err
	}
	return b, nil
}

func AddBookmark(db db.TxHandler, userID int32, resource Resource, name string) (Bookmark, error) {
	if name == "" {
		name = resource.Name()
	}
	if CheckResourceNameInvalid(name) {
		return Bookmark{}, ErrResourceNameInvalid
	}

	const q = `INSERT INTO bookmarks(user_id, resource_id, name, dir)
VALUES ($1::INT, $2::UUID, $3::TEXT, $4::BOOLEAN)
ON CONFLICT(user_id, resource_id) DO UPDATE
SET
    created = CASE WHEN bookmarks.deleted IS NULL THEN CURRENT_TIMESTAMP ELSE bookmarks.created END,
    modified = CURRENT_TIMESTAMP,
    deleted = NULL,
    name = $3::TEXT
RETURNING resource_id, name, dir, created`

	if rows, err := db.Query(q, userID, resource.ID(), name, resource.Dir()); err != nil {
		return Bookmark{}, err
	} else if bookmark, err := pgx.CollectExactlyOneRow(rows, scanBookmark); err != nil {
		return Bookmark{}, err
	} else {
		return bookmark, nil
	}
}

func RemoveBookmark(db db.TxHandler, userID int32, id uuid.UUID) error {
	const q = "DELETE FROM bookmarks WHERE user_id = $1::INT AND resource_id = $2::UUID"
	_, err := db.Exec(q, userID, id)
	return err
}

func ListBookmarks(db db.Handler, userID int32, since int64) ([]Bookmark, error) {
	sb := strings.Builder{}
	sb.WriteString(`SELECT b.resource_id, b.name, b.dir, b.created, v.mime_type
FROM bookmarks b
LEFT JOIN LATERAL
(SELECT mime_type FROM resource_versions v
	WHERE b.resource_id = v.resource_id
	ORDER BY v.created LIMIT 1) v
ON TRUE
WHERE user_id = @user_id::INT
`)
	// The delta approach currently isn't able to handle hard deletes, which happens when
	// a resource is hard deleted. Fall back to sending the full list.
	since = 0
	if since == 0 {
		sb.WriteString("AND deleted IS NULL\n")
	} else {
		sb.WriteString("AND modified >= @since::TIMESTAMPTZ\n")
	}
	sb.WriteString("ORDER BY modified DESC")

	if rows, err := db.Query(sb.String(), pgx.NamedArgs{"user_id": userID, "since": time.UnixMilli(since)}); err != nil {
		return nil, err
	} else if bookmarks, err := pgx.CollectRows(rows, scanBookmark); err != nil {
		return nil, err
	} else {
		return bookmarks, nil
	}
}
