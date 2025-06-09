package core

import (
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5/pgtype"
)

func UpdateUserHome(db db.Handler, user User, home pgtype.UUID) error {
	const q = "UPDATE users SET home = $2::UUID, modified = NOW() WHERE id = $1::INT"
	if _, err := db.Exec(q, user.ID, home); err != nil {
		return err
	}
	return nil
}

func UpdateUserName(db db.Handler, user User, name string) error {
	const q = "UPDATE users SET name = $2::TEXT, modified = NOW() WHERE id = $1::INT"
	if _, err := db.Exec(q, user.ID, name); err != nil {
		return err
	}
	return nil
}

func GrantUserPermissions(db db.Handler, user User, permissions UserPermissions) error {
	const q = "UPDATE users SET permissions = permissions | $2::INTEGER, modified = NOW() WHERE id = $1::INT"
	if _, err := db.Exec(q, user.ID, permissions); err != nil {
		return err
	}
	return nil
}

func RevokeUserPermissions(db db.Handler, user User, permissions UserPermissions) error {
	const q = "UPDATE users SET permissions = permissions & ~ $2::INTEGER, modified = NOW() WHERE id = $1::INT"
	if _, err := db.Exec(q, user.ID, permissions); err != nil {
		return err
	}
	return nil
}
