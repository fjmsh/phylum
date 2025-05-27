package user

import (
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
	"github.com/shroff/phylum/server/internal/core/util/rand"
)

const accessTokenLength = 16

var accessTokenValidity = pgtype.Interval{
	Days:  30,
	Valid: true,
}

var ErrCredentialsInvalid = errors.NewError(http.StatusUnauthorized, "credentials_invalid", "invalid Credentials")

func (m manager) VerifyUserPassword(email, password string) (User, error) {
	if user, passwordHash, err := m.userPasswordHashByEmail(email); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return User{}, ErrCredentialsInvalid
		}
		return User{}, err
	} else if passwordHash == "" {
		return User{}, ErrCredentialsInvalid
	} else {
		if b, err := crypt.VerifyPassword(password, passwordHash); err != nil {
			return User{}, err
		} else if !b {
			return User{}, ErrCredentialsInvalid
		}
		return user, nil
	}
}

func (m manager) CreateAccessToken(user User) (string, error) {
	const q = `INSERT INTO access_tokens(id, expires, user_id) VALUES ($1::TEXT, NOW() + $2::INTERVAL, $3::INT)`
	id := rand.GenerateRandomString(accessTokenLength)
	if _, err := m.db.Exec(q, id, accessTokenValidity, user.ID); err != nil {
		return "", err
	} else {
		return id, nil
	}
}

func (m manager) ReadAccessToken(accessToken string) (user User, err error) {
	const q = `SELECT t.expires, u.id, u.email, u.name, u.permissions, u.home FROM access_tokens t JOIN users u ON t.user_id = u.id WHERE t.id = $1; `
	row := m.db.QueryRow(q, accessToken)

	var expires pgtype.Timestamp
	err = row.Scan(&expires, &user.ID, &user.Email, &user.Name, &user.Permissions, &user.Home)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrCredentialsInvalid
		}
	} else if time.Now().After(expires.Time) {
		return User{}, ErrCredentialsInvalid
	}
	return
}
