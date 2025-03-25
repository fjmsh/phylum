package fs

import (
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

type Publink struct {
	ID          int32      `json:"id"`
	Name        string     `json:"name"`
	Created     time.Time  `json:"created"`
	Deleted     *time.Time `json:"deleted"`
	CreatedBy   string     `json:"creator"`
	Root        uuid.UUID  `json:"root"`
	Accessed    int32      `json:"accessed"`
	MaxAccesses int32      `json:"max_accesses"`
	Protected   bool       `json:"protected"`
	Expires     *time.Time `json:"expires"`
}

func infoFromDB(d db.Publink) Publink {
	var deleted *time.Time
	if d.Deleted.Valid {
		deleted = &d.Deleted.Time
	}
	var expires *time.Time
	if d.Expires.Valid {
		expires = &d.Expires.Time
	}
	return Publink{
		ID:          d.ID,
		Name:        d.Name,
		Created:     d.Created.Time,
		Deleted:     deleted,
		CreatedBy:   d.CreatedBy,
		Root:        d.Root,
		Accessed:    d.Accessed,
		MaxAccesses: d.MaxAccesses,
		Protected:   d.PasswordHash != "",
		Expires:     expires,
	}
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
	res, err := r.f.db.PublinksByRoot(r.f.ctx, r.ID())
	if err != nil {
		return nil, err
	}

	links := make([]Publink, len(res))
	for i, l := range res {
		links[i] = infoFromDB(l)
	}
	return links, nil
}
