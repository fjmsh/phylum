package user

import (
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

var ErrUserExists = errors.NewError(http.StatusNotFound, "user_already_exists", "user already exists")

func (m manager) CreateUser(username, displayName, password string, home uuid.UUID) (User, error) {
	const q = ` INSERT INTO users(username, display_name, password_hash, home)
VALUES ($1, $2, $3, $4)
RETURNING username, display_name, password_hash, home, permissions`

	if hash, err := crypt.GenerateArgon2EncodedHash(password); err != nil {
		return User{}, err
	} else if rows, err := m.db.Query(q, username, displayName, hash, home); err != nil {
		if strings.Contains(err.Error(), "users_pkey") {
			err = ErrUserExists
		}
		return User{}, err
	} else {
		return pgx.CollectExactlyOneRow(rows, scanUser)
	}
}
