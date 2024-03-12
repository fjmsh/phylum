package user

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/sql"
)

type Manager struct {
	queries sql.Queries
}

func NewManager(conn *pgx.Conn) Manager {
	queries := *sql.New(conn)
	return Manager{queries: queries}
}

func (m Manager) CreateUser(ctx context.Context, username, displayName, passwordHash string) error {
	_, err := m.queries.CreateUser(ctx, sql.CreateUserParams{Username: username, DisplayName: displayName, PasswordHash: passwordHash})
	if err != nil {
		return err
	}
	return nil
}

func (m Manager) FindUser(ctx context.Context, username string) (sql.User, error) {
	return m.queries.UserByUsername(ctx, username)
}
