package user

import (
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/db"
)

type manager struct {
	db db.Handler
}

func (m manager) withDb(db db.Handler) manager {
	return manager{db: db}
}

func (m manager) CreateUser(email, name string, noCreateHome bool) (User, error) {
	var user User
	err := m.db.RunInTx(func(db db.Handler) error {
		m := m.withDb(db)
		var err error
		var homeID pgtype.UUID
		var home core.Resource
		f := core.OpenOmniscient(db)
		if !noCreateHome {
			var err error
			homePath := strings.TrimRight(Cfg.BaseDir, "/") + "/" + email
			home, err = f.CreateResourceByPath(homePath, uuid.Nil, true, true, core.ResourceBindConflictResolutionEnsure)
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
			if _, err := f.UpdatePermissions(home, user.ID, core.PermissionRead|core.PermissionWrite|core.PermissionShare); err != nil {
				return err
			}
		}
		return err
	})
	return user, err
}

func (m manager) insertUser(email, name string, home pgtype.UUID) (User, error) {
	const q = ` INSERT INTO users(email, name, password_hash, home, permissions)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, email, name, home, permissions`

	if rows, err := m.db.Query(q, strings.ToLower(email), name, "", home, Cfg.Permisison); err != nil {
		return User{}, err
	} else if user, err := pgx.CollectExactlyOneRow(rows, scanUser); err != nil {
		if strings.Contains(err.Error(), "valid_email") {
			err = errors.NewError(http.StatusBadRequest, "invalid_email_address", "Invalid email address")
		}
		if strings.Contains(err.Error(), "users_email_key") {
			err = errors.NewError(http.StatusBadRequest, "user_already_exists", "User already exists")
		}
		return user, err
	} else {
		return user, err
	}
}
