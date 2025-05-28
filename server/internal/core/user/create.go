package user

import (
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/fs"
)

var errInvalidEmailAddress = errors.NewError(http.StatusBadRequest, "invalid_email_address", "Invalid email address")
var errEmailExists = errors.NewError(http.StatusBadRequest, "user_already_exists", "User already exists")

func (m manager) CreateUser(email, name string, noCreateHome bool) (User, error) {
	var user User
	err := m.db.RunInTx(func(db db.Handler) error {
		m := m.withDb(db)
		var err error
		var homeID pgtype.UUID
		var home fs.Resource
		if !noCreateHome {
			f := fs.OpenOmniscient(db)
			var err error
			homePath := strings.TrimRight(Cfg.BaseDir, "/") + "/" + email
			home, err = f.CreateResourceByPath(homePath, uuid.Nil, true, true, fs.ResourceBindConflictResolutionEnsure)
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
			if _, err := home.UpdatePermissions(user.ID, fs.PermissionRead|fs.PermissionWrite|fs.PermissionShare); err != nil {
				return err
			}
		}
		return err
	})
	return user, err
}

func (m manager) insertUser(email, name string, home pgtype.UUID) (User, error) {
	const q = ` INSERT INTO users(email, name, password_hash, home)
VALUES ($1, $2, $3, $4)
RETURNING id, email, name, home, permissions`

	if rows, err := m.db.Query(q, strings.ToLower(email), name, "", home); err != nil {
		return User{}, err
	} else if user, err := pgx.CollectExactlyOneRow(rows, scanUser); err != nil {
		if strings.Contains(err.Error(), "valid_email") {
			err = errInvalidEmailAddress
		}
		if strings.Contains(err.Error(), "users_email_key") {
			err = errEmailExists
		}
		return user, err
	} else {
		return user, err
	}
}
