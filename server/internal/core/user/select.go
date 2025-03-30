package user

import (
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/errors"
)

var ErrNotFound = errors.NewError(http.StatusNotFound, "user_not_found", "no such user")

func (m manager) ListUsers(since *time.Time) ([]User, error) {
	s := pgtype.Timestamp{
		Valid: true,
	}
	if since != nil {
		s.Time = *since
	}
	const q = "SELECT username, display_name, root, home, permissions FROM users WHERE modified > $1::TIMESTAMP"
	if rows, err := m.db.Query(m.ctx, q, s); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanUser)
	}
}

func (m manager) UserByEmail(email string) (User, error) {
	result, err := m.db.UserByUsername(m.ctx, email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrNotFound
		}
		return User{}, err
	}
	return User{
		Username:    result.Username,
		DisplayName: result.DisplayName,
		Permissions: result.Permissions,
		Root:        result.Root,
		Home:        result.Home,
	}, nil
}
