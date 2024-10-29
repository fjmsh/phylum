package publink

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

var ErrUnauthorized = errors.New("unauthorized")
var ErrNotFound = errors.New("not found")

func OpenResource(ctx context.Context, name string, password string, path string) (Resource, error) {
	d := db.Get()
	// Check exists
	s, err := d.GetPublink(ctx, name)
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

	f := filesystem{
		ctx:  ctx,
		db:   db.Get(),
		cs:   storage.Get(),
		root: s.Root,
	}

	return f.resourceByPath(path)
}
