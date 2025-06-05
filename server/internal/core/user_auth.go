package core

import (
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/crypt"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/rand"
)

const accessTokenLength = 16
const resetTokenLength = 64
const resetTokenDuration = 10 * time.Minute

var accessTokenValidity = pgtype.Interval{
	Days:  30,
	Valid: true,
}

var ErrCredentialsInvalid = NewError(http.StatusUnauthorized, "credentials_invalid", "invalid Credentials")
var errTokenNotFound = NewError(http.StatusBadRequest, "token_not_found", "Token Not Found")

func (m manager) VerifyUserPassword(email, password string) (User, error) {
	if user, passwordHash, err := m.userPasswordHashByEmail(email); err != nil {
		if Is(err, pgx.ErrNoRows) {
			return User{}, ErrCredentialsInvalid
		}
		return User{}, err
	} else if passwordHash == "" {
		return User{}, ErrCredentialsInvalid
	} else {
		if b, err := crypt.Verify(password, passwordHash); err != nil {
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
		if Is(err, pgx.ErrNoRows) {
			err = ErrCredentialsInvalid
		}
	} else if time.Now().After(expires.Time) {
		return User{}, ErrCredentialsInvalid
	}
	return
}

func (m manager) CreateResetToken(user User) (string, error) {
	const q = `INSERT INTO reset_tokens(user_id, token, expires)
VALUES (@user_id::INT, @token::TEXT, @expires::TIMESTAMP)
ON CONFLICT(user_id) DO UPDATE SET token = @token::TEXT, expires = @expires::TIMESTAMP`
	token := rand.GenerateRandomString(resetTokenLength)

	args := pgx.NamedArgs{
		"user_id": user.ID,
		"token":   token,
		"expires": time.Now().Add(resetTokenDuration),
	}
	if _, err := m.db.Exec(q, args); err != nil {
		return "", err
	}
	return token, nil
}

func (m manager) ResetUserPassword(user User, token, password string) error {
	const q = `DELETE FROM reset_tokens WHERE user_id = @user_id::INT AND token = @token::TEXT RETURNING expires`
	args := pgx.NamedArgs{
		"user_id": user.ID,
		"token":   token,
		"expires": time.Now().Add(resetTokenDuration),
	}
	return m.db.RunInTx(func(d db.Handler) error {
		m := m.withDb(d)

		// UpdateUserPassword will ensure the password strength
		// Not incorrect to do this before token verification because we are in a transaction.
		// TODO: Are there perf implications for this in case of malicious actors?
		err := m.UpdateUserPassword(user, password)
		if err != nil {
			return err
		}
		row := m.db.QueryRow(q, args)
		var expires pgtype.Timestamp
		if err := row.Scan(&expires); err == nil {
			if time.Now().After(expires.Time) {
				return errTokenNotFound
			}
			return nil
		} else if Is(err, pgx.ErrNoRows) {
			return errTokenNotFound
		} else {
			return err
		}
	})

}
