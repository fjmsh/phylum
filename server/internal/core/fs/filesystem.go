package fs

import (
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
)

type filesystem struct {
	db         db.Handler
	pathRoot   pgtype.UUID
	userID     int32
	fullAccess bool
}

func (f filesystem) WithDb(db db.Handler) FileSystem {
	return f.withDb(db)
}

func (f filesystem) withDb(db db.Handler) filesystem {
	return filesystem{
		db:         db,
		pathRoot:   f.pathRoot,
		userID:     f.userID,
		fullAccess: f.fullAccess,
	}
}

func (f filesystem) WithPathRoot(pathRoot pgtype.UUID) FileSystem {
	return f.withPathRoot(pathRoot)
}

func (f filesystem) withPathRoot(pathRoot pgtype.UUID) filesystem {
	return filesystem{
		db:         f.db,
		pathRoot:   pathRoot,
		userID:     f.userID,
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
