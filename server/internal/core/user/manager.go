package user

import (
	"context"

	"github.com/shroff/phylum/server/internal/core/db"
)

type manager struct {
	db  *db.DbHandler
	ctx context.Context
}

func (m manager) WithDb(db *db.DbHandler) Manager {
	return m.withDb(db)
}

func (m manager) withDb(db *db.DbHandler) manager {
	return manager{
		ctx: m.ctx,
		db:  db,
	}
}
