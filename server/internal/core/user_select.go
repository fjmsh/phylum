package core

import (
	"net/http"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var ErrUserNotFound = NewError(http.StatusNotFound, "user_not_found", "no such user")

func CreateUser(db db.TxHandler, email, name string, noCreateHome bool) (User, error) {
	f := openSUFileSystemTx(db)
	var homeID pgtype.UUID
	var home Resource
	if !noCreateHome {
		var err error
		homePath := strings.TrimRight(userConfig.BaseDir, "/") + "/" + email
		home, err = f.CreateResourceByPath(homePath, uuid.Nil, true, true, ResourceBindConflictResolutionEnsure)
		if err != nil {
			return User{}, err
		}
		homeID = pgtype.UUID{Bytes: home.ID(), Valid: true}
	}

	user, err := insertUser(db, email, name, homeID)
	if err != nil {
		return User{}, err
	}

	if homeID.Valid {
		if _, err := f.UpdatePermissions(home, user, PermissionAll); err != nil {
			return User{}, err
		}
	}
	return user, nil
}

func ListUsers(db db.Handler, since int64) ([]User, error) {
	sb := strings.Builder{}
	sb.WriteString("SELECT id, email, name, home, permissions FROM users")
	if since > 0 {
		sb.WriteString(" WHERE modified >= @since::TIMESTAMPTZ ")
	}
	if rows, err := db.Query(sb.String(), pgx.NamedArgs{"since": time.UnixMilli(since)}); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanUser)
	}
}

func UserEmailByID(db db.Handler, id int) (string, error) {
	const q = "SELECT email FROM users WHERE id = $1"
	row := db.QueryRow(q, id)
	var email string
	if err := row.Scan(&email); err != nil {
		return "", err
	} else {
		return email, nil
	}
}

func UserByEmail(db db.Handler, email string) (User, error) {
	const q = "SELECT id, email, name, home, permissions FROM users WHERE email = $1"
	if rows, err := db.Query(q, strings.ToLower(email)); err != nil {
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

func UserByID(db db.Handler, userID int32) (User, error) {
	const q = "SELECT id, email, name, home, permissions FROM users WHERE id = $1"
	if rows, err := db.Query(q, userID); err != nil {
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

func UserHome(db db.Handler, email string) (pgtype.UUID, error) {
	const q = "SELECT home FROM users WHERE email = $1"
	row := db.QueryRow(q, strings.ToLower(email))
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

func insertUser(db db.Handler, email, name string, home pgtype.UUID) (User, error) {
	const q = ` INSERT INTO users(email, name, password_hash, home, permissions)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, email, name, home, permissions`

	if rows, err := db.Query(q, strings.ToLower(email), name, "", home, userConfig.Permissions); err != nil {
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
		return user, nil
	}
}
