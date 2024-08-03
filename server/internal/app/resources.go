package app

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/sql"
)

var ErrResourceNotFound = errors.New("resource not found")

func (a *App) LocateResource(id uuid.UUID, username string) (uuid.UUID, int, error) {
	result, err := a.Db.Queries().PermissionsForResource(context.Background(), sql.PermissionsForResourceParams{ResourceID: id, Username: username})
	if err == pgx.ErrNoRows {
		err = ErrResourceNotFound
	}
	if err != nil {
		return uuid.UUID{}, 0, err
	}

	return result.ID, int(result.Permission.Int32), nil
}
