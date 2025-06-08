package core

import (
	"strings"

	"codeberg.org/shroff/phylum/server/internal/crypt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f filesystem) CreatePublink(r Resource, id, password string, expires pgtype.Timestamp, accessLimit int) error {
	if !r.hasPermission(PermissionShare | PermissionRead) {
		return ErrInsufficientPermissions
	}
	if r.deleted.Valid {
		return ErrResourceDeleted
	}

	passwordHash := ""

	if password != "" {
		hash, err := crypt.Generate(password)
		if err != nil {
			return err
		}
		passwordHash = hash
	}

	const q = `INSERT INTO publinks(id, root, password_hash, expires, access_limit) VALUES
	($1::text, $2::uuid, $3::text, $4::timestamp, $5::int)`

	_, err := f.db.Exec(q, id, r.ID(), passwordHash, expires, accessLimit)
	if err != nil && strings.Contains(err.Error(), "publinks_pkey") {
		return ErrPublinkNameConflict
	}
	return err
}

func (f filesystem) ListPublinks(r Resource) ([]Publink, error) {
	const q = "SELECT * FROM publinks WHERE root = $1::UUID"
	if rows, err := f.db.Query(q, r.id); err != nil {
		return nil, err
	} else if links, err := pgx.CollectRows(rows, scanPublink); err != nil {
		return nil, err
	} else {
		return links, nil
	}
}
