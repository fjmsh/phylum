package user

import (
	"context"

	"github.com/shroff/phylum/server/internal/db"
)

type manager struct {
	db db.Handler
}

func (m manager) withDb(db db.Handler) manager {
	return manager{db: db}
}

func ManagerFromContext(ctx context.Context) Manager {
	return manager{db: db.Get(ctx)}
}

func ManagerFromDB(db db.Handler) Manager {
	return manager{db: db}
}
