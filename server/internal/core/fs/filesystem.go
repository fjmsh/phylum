package fs

import (
	"context"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type filesystem struct {
	db       *db.DbHandler
	ctx      context.Context
	cs       storage.Storage
	rootID   uuid.UUID
	username string
}

func (f filesystem) RootID() uuid.UUID {
	return f.rootID
}

func (f filesystem) WithRoot(id uuid.UUID) FileSystem {
	return f.withRoot(id)
}

func (f filesystem) withRoot(id uuid.UUID) filesystem {
	return filesystem{
		db:       f.db,
		ctx:      f.ctx,
		cs:       f.cs,
		rootID:   id,
		username: f.username,
	}
}

func (f filesystem) WithDb(db *db.DbHandler) FileSystem {
	return f.withDb(db)
}

func (f filesystem) withDb(db *db.DbHandler) filesystem {
	return filesystem{
		db:       db,
		ctx:      f.ctx,
		cs:       f.cs,
		rootID:   f.rootID,
		username: f.username,
	}
}

func (f filesystem) RunInTx(fn func(FileSystem) error) error {
	return f.db.WithTx(f.ctx, func(db *db.DbHandler) error {
		return fn(f.WithDb(db))
	})
}
