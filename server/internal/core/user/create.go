package user

import (
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

var ErrInvalidEmailAddress = errors.NewError(http.StatusBadRequest, "invalid_email_address", "Invalid email address")
var ErrUserExists = errors.NewError(http.StatusBadRequest, "user_already_exists", "User already exists")

func (m manager) CreateUser(email, displayName, password string, home pgtype.UUID) (User, error) {
	const q = ` INSERT INTO users(email, display_name, password_hash, home)
VALUES ($1, $2, $3, $4)
RETURNING id, email, display_name, home, permissions`

	if hash, err := crypt.GenerateArgon2EncodedHash(password); err != nil {
		return User{}, err
	} else if rows, err := m.db.Query(q, strings.ToLower(email), displayName, hash, home); err != nil {
		return User{}, err
	} else if user, err := pgx.CollectExactlyOneRow(rows, scanUser); err != nil {
		if strings.Contains(err.Error(), "valid_email") {
			err = ErrInvalidEmailAddress
		}
		if strings.Contains(err.Error(), "users_email_key") {
			err = ErrUserExists
		}
		return user, err
	} else {
		return user, err
	}
}
