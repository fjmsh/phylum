package core

import (
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f *FileSystem) CreatePublink(r Resource, id, password string, expires pgtype.Timestamp, accessLimit int) error {
	return f.runInTx(func(f txFileSystem) error {
		return f.CreatePublink(r, id, password, expires, accessLimit)
	})
}

func (f txFileSystem) CreatePublink(r Resource, id, password string, expires pgtype.Timestamp, accessLimit int) error {
	if err := f.checkPermission(r, ResourcePermissionShare|ResourcePermissionRead); err != nil {
		return err
	}
	if r.deleted.Valid {
		return ErrResourceDeleted
	}

	passwordHash := ""

	if password != "" {
		var err error
		passwordHash, err = publinksPasswordHasher.GenerateEncodedHash(password)
		if err != nil {
			return errors.New("failed to hash password: " + err.Error())
		}
	}

	const q = `INSERT INTO publinks(id, root, password_hash, expires, access_limit) VALUES
	($1::text, $2::uuid, $3::text, $4::timestamp, $5::int)`

	_, err := f.db.Exec(q, id, r.ID(), passwordHash, expires, accessLimit)
	if err != nil && strings.Contains(err.Error(), "publinks_pkey") {
		return ErrPublinkNameConflict
	}
	return err
}

func (f *FileSystem) ListPublinks(r Resource) ([]Publink, error) {
	const q = "SELECT * FROM publinks WHERE root = $1::UUID"
	if rows, err := f.db.Query(q, r.id); err != nil {
		return nil, err
	} else if links, err := pgx.CollectRows(rows, scanPublink); err != nil {
		return nil, err
	} else {
		return links, nil
	}
}
