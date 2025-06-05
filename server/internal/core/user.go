package core

import (
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type User struct {
	ID          int32
	Email       string
	Name        string
	Home        pgtype.UUID
	Permissions Permissions
}

func scanUser(row pgx.CollectableRow) (User, error) {
	var u User
	err := row.Scan(
		&u.ID,
		&u.Email,
		&u.Name,
		&u.Home,
		&u.Permissions,
	)
	return u, err
}
