package publink

import (
	"context"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

var ErrNotFound = errors.NewError(http.StatusNotFound, "publink_not_found", "publink not found")

func OpenResource(ctx context.Context, name string, password string, path string) (Resource, error) {
	// Check exists
	s, err := db.Get().GetPublink(ctx, name)
	if errors.Is(err, pgx.ErrNoRows) {
		err = ErrNotFound
	}
	if err != nil {
		return Resource{}, err
	}

	// check password
	if s.PasswordHash.Valid {
		if ok, err := crypt.VerifyPassword(password, s.PasswordHash.String); err != nil {
			return Resource{}, err
		} else if !ok {
			return Resource{}, auth.ErrRequired
		}
	}

	// check expiration
	if s.Expires.Valid {
		if s.Expires.Time.Before(time.Now()) {
			return Resource{}, ErrNotFound
		}
	}

	// check max accesses
	if s.MaxAccesses.Valid {
		if s.MaxAccesses.Int32 <= s.Accessed {
			return Resource{}, ErrNotFound
		}
	}
	db.Get().MarkPublinkAccess(ctx, s.ID)

	f := filesystem{
		ctx:    ctx,
		db:     db.Get(),
		cs:     storage.Get(),
		rootID: s.Root,
	}
	return f.ResourceByPath(path)
}
