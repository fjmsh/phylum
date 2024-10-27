package fs

import (
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

func (r Resource) CreatePublicShare(name string, password *string, maxAge *time.Time, maxDownloads *int) error {
	if !r.hasPermission(PermissionShare | PermissionRead) {
		return ErrInsufficientPermissions
	}

	passwordHash := pgtype.Text{}
	expires := pgtype.Timestamp{}
	accessesLeft := pgtype.Int4{}

	if password != nil {
		hash, err := crypt.GenerateArgon2EncodedHash(*password)
		if err != nil {
			return err
		}
		passwordHash = pgtype.Text{
			String: hash,
			Valid:  true,
		}
	}
	if maxAge != nil {
		expires = pgtype.Timestamp{
			Time:  *maxAge,
			Valid: true,
		}
	}

	if maxDownloads != nil {
		accessesLeft = pgtype.Int4{
			Int32: int32(*maxDownloads),
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
