package fs

import (
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

type Publink struct {
	ID           int32
	Name         string
	Created      time.Time
	Deleted      pgtype.Timestamp
	CreatedBy    string
	Root         uuid.UUID
	Accessed     int32
	MaxAccesses  int32
	PasswordHash string
	Expires      pgtype.Timestamp
}

func scanPublink(row pgx.CollectableRow) (Publink, error) {
	var p Publink
	if err := row.Scan(
		&p.ID,
		&p.Name,
		&p.Created,
		&p.Deleted,
		&p.CreatedBy,
		&p.Root,
		&p.Accessed,
		&p.MaxAccesses,
		&p.PasswordHash,
		&p.Expires,
	); err != nil {
		return Publink{}, err
	}
	return p, nil
}

func (r Resource) CreatePublink(name, password string, duration time.Duration, accesses int) error {
	if !r.hasPermission(PermissionShare | PermissionRead) {
		return ErrInsufficientPermissions
	}

	passwordHash := ""

	if password != "" {
		hash, err := crypt.GenerateArgon2EncodedHash(password)
		if err != nil {
			return err
		}
		passwordHash = hash
	}

	expires := pgtype.Timestamp{}
	if duration != 0 {
		expires = pgtype.Timestamp{
			Time:  time.Now().Add(duration),
			Valid: true,
		}
	}

	return r.f.db.CreatePublink(r.f.ctx, db.CreatePublinkParams{
		Name:         name,
		CreatedBy:    r.f.username,
		Root:         r.ID(),
		PasswordHash: passwordHash,
		Expires:      expires,
		MaxAccesses:  int32(accesses),
	})
}

func (r Resource) ListPublinks() ([]Publink, error) {
	const q = "SELECT * FROM publinks WHERE root = $1::UUID"
	if rows, err := r.f.db.Query(r.f.ctx, q, r.id); err != nil {
		return nil, err
	} else if links, err := pgx.CollectRows(rows, scanPublink); err != nil {
		return nil, err
	} else {
		return links, nil
	}
}
