package user

import (
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/errors"
)

var ErrNotFound = errors.NewError(http.StatusNotFound, "user_not_found", "no such user")

func (m manager) ListUsers(since *time.Time) ([]BasicUser, error) {
	s := pgtype.Timestamp{
		Valid: true,
	}
	if since != nil {
		s.Time = *since
	}
	const q = "SELECT username, display_name FROM users WHERE modified > $1::TIMESTAMP"
	if rows, err := m.db.Query(q, s); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanBasicUser)
	}
}

func (m manager) UserByEmail(email string) (User, error) {
	const q = "SELECT username, display_name, password_hash, root, home, permissions FROM users WHERE username = $1"
	if rows, err := m.db.Query(q, email); err != nil {
		return User{}, err
	} else if u, err := pgx.CollectExactlyOneRow(rows, scanUser); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrNotFound
		}
		return User{}, err
	} else {
		return u, nil
	}
}
