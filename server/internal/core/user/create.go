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

func (m manager) CreateUser(username, displayName, password string, root uuid.UUID) (User, error) {
	const q = ` INSERT INTO users(username, display_name, password_hash, root, home)
VALUES ($1, $2, $3, $4, $5)
RETURNING username, display_name, password_hash, root, home, permissions`

	if hash, err := crypt.GenerateArgon2EncodedHash(password); err != nil {
		return User{}, err
	} else if rows, err := m.db.Query(m.ctx, q, username, displayName, hash, root, root); err != nil {
		if strings.Contains(err.Error(), "users_pkey") {
			err = ErrUserExists
		}
		return User{}, err
	} else {
		return pgx.CollectExactlyOneRow(rows, scanUser)
	}
}
