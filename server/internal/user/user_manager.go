package user

import (
	"context"

	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/sql"
)

type Manager struct {
	db *sql.DbHandler
}

func NewManager(db *sql.DbHandler) (*Manager, error) {
	return &Manager{db: db}, nil
}

func (m Manager) CreateUser(ctx context.Context, username, displayName, password string) error {
	if hash, err := cryptutil.GenerateArgon2EncodedHash(password, cryptutil.DefaultArgon2Params()); err != nil {
		return err
	} else if err = m.db.Queries().CreateUser(ctx, sql.CreateUserParams{Username: username, DisplayName: displayName, PasswordHash: hash}); err != nil {
		return err
	}
	return nil
}

func (m Manager) ListUsers(ctx context.Context) ([]sql.User, error) {
	return m.db.Queries().ListUsers(ctx)
}

func (m Manager) FindUser(ctx context.Context, username string) (sql.User, error) {
	return m.db.Queries().UserByUsername(ctx, username)
}
