package fs

import (
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type filesystem struct {
	db         db.Handler
	cs         storage.Storage
	pathRoot   pgtype.UUID
	username   string
	fullAccess bool
}

func (f filesystem) WithDb(db db.Handler) FileSystem {
	return f.withDb(db)
}

func (f filesystem) withDb(db db.Handler) filesystem {
	return filesystem{
		db:         db,
		cs:         f.cs,
		pathRoot:   f.pathRoot,
		username:   f.username,
		fullAccess: f.fullAccess,
	}
}

func (f filesystem) WithPathRoot(pathRoot pgtype.UUID) FileSystem {
	return filesystem{
		db:         f.db,
		cs:         f.cs,
		pathRoot:   pathRoot,
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
