package user

import (
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

var ErrUserExists = errors.NewError(http.StatusNotFound, "user_already_exists", "user already exists")

func (m manager) CreateUser(username, displayName, password string, root uuid.UUID) (User, error) {
	if hash, err := crypt.GenerateArgon2EncodedHash(password); err != nil {
		return User{}, err
	} else if u, err := m.db.CreateUser(m.ctx, db.CreateUserParams{
		Username:     username,
		DisplayName:  displayName,
		PasswordHash: hash,
		Root:         root,
		Home:         root,
	}); err != nil {
		if strings.Contains(err.Error(), "users_pkey") {
			err = ErrUserExists
		}
		return User{}, err
	} else {
		return User{
			Username:    u.Username,
			DisplayName: u.DisplayName,
			Root:        u.Root,
			Home:        u.Home,
		}, nil
	}
}
