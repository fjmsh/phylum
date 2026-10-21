package core

import (
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func UpdateUserHome(db db.TxHandler, userID int32, home pgtype.UUID) (User, error) {
	const q = "UPDATE users SET home = $2::UUID, modified = NOW() WHERE id = $1::INT RETURNING id, email, name, home, permissions"
	if rows, err := db.Query(q, userID, home); err != nil {
		return User{}, err
	} else {
		return pgx.CollectExactlyOneRow(rows, scanUser)
	}
}

func UpdateUserName(db db.TxHandler, userID int32, name string) (User, error) {
	const q = "UPDATE users SET name = $2::TEXT, modified = NOW() WHERE id = $1::INT RETURNING id, email, name, home, permissions"
	if rows, err := db.Query(q, userID, name); err != nil {
		return User{}, err
	} else {
		return pgx.CollectExactlyOneRow(rows, scanUser)
	}
}

func SetUserPrivileges(db db.TxHandler, userID int32, permissions UserPrivileges) error {
	const q = "UPDATE users SET permissions = $2::TEXT[], modified = NOW() WHERE id = $1::INT"
	if _, err := db.Exec(q, userID, permissions); err != nil {
		return err
	}
	return nil
}
