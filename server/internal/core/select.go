package core

import (
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var ErrNotFound = NewError(http.StatusNotFound, "user_not_found", "no such user")

func (m manager) ListUsers(since int64) ([]User, error) {
	sb := strings.Builder{}
	sb.WriteString("SELECT id, email, name, home, permissions FROM users")
	if since > 0 {
		sb.WriteString(" WHERE modified >= @since::TIMESTAMP")
	}
	if rows, err := m.db.Query(sb.String(), pgx.NamedArgs{"since": time.UnixMilli(since).UTC()}); err != nil {
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
		if Is(err, pgx.ErrNoRows) {
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
	if Is(err, pgx.ErrNoRows) {
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
		if Is(err, pgx.ErrNoRows) {
			err = ErrNotFound
		}
		return pgtype.UUID{}, err
	}
}
