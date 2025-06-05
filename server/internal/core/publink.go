package core

import (
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type Publink struct {
	ID           string
	Created      time.Time
	Root         uuid.UUID
	Accessed     int32
	AccessLimit  int32
	PasswordHash string
	Expires      int64
}

func scanPublink(row pgx.CollectableRow) (Publink, error) {
	var p Publink
	var expires *time.Time
	if err := row.Scan(
		&p.ID,
		&p.Created,
		&p.Root,
		&p.Accessed,
		&p.AccessLimit,
		&p.PasswordHash,
		&expires,
	); err != nil {
		return Publink{}, err
	}
	if expires != nil {
		p.Expires = expires.UnixMilli()
	}
	return p, nil
}
