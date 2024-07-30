package app

import (
	"context"

	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/sql"
)

func (a App) CreateUser(ctx context.Context, username, displayName, password string) error {
	if hash, err := cryptutil.GenerateArgon2EncodedHash(password, cryptutil.DefaultArgon2Params()); err != nil {
		return err
	} else if err = a.Db.Queries().CreateUser(ctx, sql.CreateUserParams{Username: username, DisplayName: displayName, PasswordHash: hash}); err != nil {
		return err
	}
	return nil
}

func (a App) ListUsers(ctx context.Context) ([]sql.User, error) {
	return a.Db.Queries().ListUsers(ctx)
}

func (a App) FindUser(ctx context.Context, username string) (sql.User, error) {
	return a.Db.Queries().UserByUsername(ctx, username)
}
