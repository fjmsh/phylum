package user

import (
	"context"

	"github.com/shroff/phylum/server/internal/core/db"
)

type manager struct {
	db db.Handler
}

func ManagerFromContext(ctx context.Context) Manager {
	return manager{db: db.Get(ctx)}
}

func ManagerFromDB(db db.Handler) Manager {
	return manager{db: db}
}
