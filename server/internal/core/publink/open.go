package publink

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

var ErrUnauthorized = errors.NewError(http.StatusUnauthorized, "", "Unauthorized")
var ErrNotFound = errors.NewError(http.StatusNotFound, "", "Not Found")

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
	if s.PasswordHash != "" {
		if password == "" {
			return Resource{}, ErrUnauthorized
		}
		if ok, err := crypt.VerifyPassword(password, s.PasswordHash); err != nil {
			return Resource{}, err
		} else if !ok {
			return Resource{}, ErrUnauthorized
		}
	}

	// check expiration
	if s.Expires.Valid && s.Expires.Time.Before(time.Now()) {
		return Resource{}, ErrNotFound
	}

	// check max accesses
	if s.MaxAccesses > 0 && s.MaxAccesses <= s.Accessed {
		return Resource{}, ErrNotFound
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
