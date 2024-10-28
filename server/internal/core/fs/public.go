package fs

import (
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

func (r Resource) CreatePublicShare(name, password string, maxAge time.Duration, accesses int) error {
	if !r.hasPermission(PermissionShare | PermissionRead) {
		return ErrInsufficientPermissions
	}

	passwordHash := pgtype.Text{}
	expires := pgtype.Timestamp{}
	accessesLeft := pgtype.Int4{}

	if password != "" {
		hash, err := crypt.GenerateArgon2EncodedHash(password)
		if err != nil {
			return err
		}
		passwordHash = pgtype.Text{
			String: hash,
			Valid:  true,
		}
	}
	if maxAge != 0 {
		expires = pgtype.Timestamp{
			Time:  time.Now().Add(maxAge),
			Valid: true,
		}
	}

	if accesses != 0 {
		accessesLeft = pgtype.Int4{
			Int32: int32(accesses),
			Valid: true,
		}
	}

	return r.f.db.CreatePublicShare(r.f.ctx, db.CreatePublicShareParams{
		ID:           name,
		CreatedBy:    r.f.username,
		Root:         r.ID,
		PasswordHash: passwordHash,
		Expires:      expires,
		AccessesLeft: accessesLeft,
	})
}
