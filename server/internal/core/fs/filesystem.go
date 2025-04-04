package fs

import (
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type filesystem struct {
	db         db.Handler
	cs         storage.Storage
	rootID     uuid.UUID
	username   string
	fullAccess bool
}

func (f filesystem) RootID() uuid.UUID {
	return f.rootID
}

func (f filesystem) WithRoot(id uuid.UUID) FileSystem {
	return f.withRoot(id)
}

func (f filesystem) withRoot(id uuid.UUID) filesystem {
	return filesystem{
		db:         f.db,
		cs:         f.cs,
		rootID:     id,
		username:   f.username,
		fullAccess: f.fullAccess,
	}
}

func (f filesystem) WithDb(db db.Handler) FileSystem {
	return f.withDb(db)
}

func (f filesystem) withDb(db db.Handler) filesystem {
	return filesystem{
		db:         db,
		cs:         f.cs,
		rootID:     f.rootID,
		username:   f.username,
		fullAccess: f.fullAccess,
	}
}

func (f filesystem) RunInTx(fn func(FileSystem) error) error {
	return f.db.RunInTx(func(db db.Handler) error {
		return fn(f.WithDb(db))
	})
}

func (f filesystem) runInTx(fn func(filesystem) error) error {
	return f.db.RunInTx(func(db db.Handler) error {
		return fn(f.withDb(db))
	})
}
