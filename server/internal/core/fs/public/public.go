package public

import (
	"context"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

var ErrPublicShareNotFound = errors.NewError(http.StatusUnauthorized, "public_share_not_found", "public share not found")


func OpenPublic(ctx context.Context, id string, password string) (FileSystem, error) {
	// Check exists
	s, err := db.Get().PublicShare(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		err = ErrPublicShareNotFound
	}
	if err != nil {
		return nil, err
	}

	// check password
	if s.PasswordHash.Valid {
		if ok, err := crypt.VerifyPassword(password, s.PasswordHash.String); err != nil {
			return nil, err
		} else if !ok {
			return nil, ErrPublicShareNotFound
		}
	}

	// check expiration
	if s.Expires.Valid {
		if s.Expires.Time.Before(time.Now()) {
			return nil, ErrPublicShareNotFound
		}
	}

	// check max accesses
	if s.AccessesLeft.Valid {
		if s.AccessesLeft.Int32 <= 0 {
			return nil, ErrPublicShareNotFound
		}
		db.Get().AccessPublicShare(ctx, id)
	}

	return filesystem{
		ctx:    ctx,
		db:     db.Get(),
		cs:     storage.Get(),
		rootID: s.Root,
	}, nil
}
