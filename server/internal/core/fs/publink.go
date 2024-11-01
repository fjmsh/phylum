package fs

import (
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/publink"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

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

func (r Resource) ListPublinks() ([]publink.Info, error) {
	res, err := r.f.db.PublinksByRoot(r.f.ctx, r.ID())
	if err != nil {
		return nil, err
	}

	links := make([]publink.Info, len(res))
	for i, l := range res {
		links[i] = publink.InfoFromDB(l)
	}
	return links, nil
}
