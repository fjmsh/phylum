package user

import (
	"net/http"
	"strings"
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
	const q = "SELECT id, email, name, home, permissions FROM users WHERE modified > $1::TIMESTAMP"
	if rows, err := m.db.Query(q, s); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanUser)
	}
}

func (m manager) UserByEmail(email string) (User, error) {
	const q = "SELECT id, email, name, home, permissions FROM users WHERE email = $1"
	if rows, err := m.db.Query(q, strings.ToLower(email)); err != nil {
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

func (m manager) userPasswordHashByEmail(email string) (user User, passwordHash string, err error) {
	const q = "SELECT id, email, name, home, permissions, password_hash FROM users WHERE email = $1"
	row := m.db.QueryRow(q, strings.ToLower(email))
	err = row.Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&user.Home,
		&user.Permissions,
		&passwordHash)
	if errors.Is(err, pgx.ErrNoRows) {
		err = ErrNotFound
	}
	return
}

func (m manager) UserHome(email string) (pgtype.UUID, error) {
	const q = "SELECT home FROM users WHERE email = $1"
	row := m.db.QueryRow(q, strings.ToLower(email))
	var id pgtype.UUID
	if err := row.Scan(&id); err == nil {
		if !id.Valid {
			err = ErrNotFound
		}
		return id, err
	} else {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrNotFound
		}
		return pgtype.UUID{}, err
	}
}
