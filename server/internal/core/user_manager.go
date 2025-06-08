package core

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/db"
)

var ErrUserNotFound = NewError(http.StatusNotFound, "user_not_found", "no such user")

type manager struct {
	db db.Handler
}

func (m manager) withDb(db db.Handler) manager {
	return manager{db: db}
}

func UserManagerFromContext(ctx context.Context) UserManager {
	return manager{db: db.Get(ctx)}
}

func UserManagerFromDB(db db.Handler) UserManager {
	return manager{db: db}
}

func (m manager) CreateUser(email, name string, noCreateHome bool) (User, error) {
	var user User
	err := m.db.RunInTx(func(db db.Handler) error {
		m := m.withDb(db)
		var err error
		var homeID pgtype.UUID
		var home Resource
		f := OpenOmniscient(db)
		if !noCreateHome {
			var err error
			homePath := strings.TrimRight(Cfg.BaseDir, "/") + "/" + email
			home, err = f.CreateResourceByPath(homePath, uuid.Nil, true, true, ResourceBindConflictResolutionEnsure)
			if err != nil {
				return err
			}
			homeID = pgtype.UUID{Bytes: home.ID(), Valid: true}
		}

		user, err = m.insertUser(email, name, homeID)
		if err != nil {
			return err
		}

		if homeID.Valid {
			if _, err := f.UpdatePermissions(home, user, PermissionRead|PermissionWrite|PermissionShare); err != nil {
				return err
			}
		}
		return err
	})
	return user, err
}

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

func (m manager) UserEmailByID(id int) (string, error) {
	const q = "SELECT email FROM users WHERE id = $1"
	row := m.db.QueryRow(q, id)
	var email string
	if err := row.Scan(&email); err != nil {
		return "", err
	} else {
		return email, nil
	}
}

func (m manager) UserByEmail(email string) (User, error) {
	const q = "SELECT id, email, name, home, permissions FROM users WHERE email = $1"
	if rows, err := m.db.Query(q, strings.ToLower(email)); err != nil {
		return User{}, err
	} else if u, err := pgx.CollectExactlyOneRow(rows, scanUser); err != nil {
		if Is(err, pgx.ErrNoRows) {
			err = ErrUserNotFound
		}
		return User{}, err
	} else {
		return u, nil
	}
}

func (m manager) UserHome(email string) (pgtype.UUID, error) {
	const q = "SELECT home FROM users WHERE email = $1"
	row := m.db.QueryRow(q, strings.ToLower(email))
	var id pgtype.UUID
	if err := row.Scan(&id); err == nil {
		if !id.Valid {
			err = ErrUserNotFound
		}
		return id, err
	} else {
		if Is(err, pgx.ErrNoRows) {
			err = ErrUserNotFound
		}
		return pgtype.UUID{}, err
	}
}

func (m manager) insertUser(email, name string, home pgtype.UUID) (User, error) {
	const q = ` INSERT INTO users(email, name, password_hash, home, permissions)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, email, name, home, permissions`

	if rows, err := m.db.Query(q, strings.ToLower(email), name, "", home, Cfg.Permisison); err != nil {
		return User{}, err
	} else if user, err := pgx.CollectExactlyOneRow(rows, scanUser); err != nil {
		if strings.Contains(err.Error(), "valid_email") {
			err = NewError(http.StatusBadRequest, "invalid_email_address", "Invalid email address")
		}
		if strings.Contains(err.Error(), "users_email_key") {
			err = NewError(http.StatusBadRequest, "user_already_exists", "User already exists")
		}
		return user, err
	} else {
		return user, err
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
		err = ErrUserNotFound
	}
	return
}
