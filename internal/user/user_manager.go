package user

import (
	"context"

	"github.com/shroff/phylum/server/internal/sql"
)

type Manager struct {
	db *sql.DbHandler
}

func NewManager(db *sql.DbHandler) Manager {
	return Manager{db: db}
}

func (m Manager) CreateUser(ctx context.Context, username, displayName, passwordHash string) error {
	_, err := m.db.Queries().CreateUser(ctx, sql.CreateUserParams{Username: username, DisplayName: displayName, PasswordHash: passwordHash})
	if err != nil {
		return err
	}
	return nil
}

func (m Manager) FindUser(ctx context.Context, username string) (sql.User, error) {
	return m.db.Queries().UserByUsername(ctx, username)
}
