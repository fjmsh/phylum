package auth

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"net/http"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/auth/ldap"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/rs/zerolog"
)

var cfg Config
var passwordBackend PasswordBackend

const apiTokenLength = 32
const resetTokenLength = 24
const resetTokenDuration = 10 * time.Minute

var accessTokenValidity = pgtype.Interval{
	Days:  30,
	Valid: true,
}

var ErrCredentialsInvalid = core.NewError(http.StatusUnauthorized, "credentials_invalid", "invalid credentials")

func SupportsPasswordAuth() bool {
	return passwordBackend != nil
}

func SupportsPasswordReset() bool {
	return passwordBackend != nil && passwordBackend.SupportsPasswordUpdate()
}

func Init(cfg Config, log zerolog.Logger) error {
	if cfg.Password.Backend == "crypt" {
		passwordBackend = &crypt.Auth{}
	} else if cfg.Password.Backend == "ldap" {
		if a, err := ldap.NewAuth(cfg.Password.LDAP, log); err != nil {
			return err
		} else {
			passwordBackend = a
		}
	} else if cfg.Password.Backend != "" {
		return errors.New("password backend not recognized: " + cfg.Password.Backend)
	}
	return nil
}

func VerifyUserPassword(db db.Handler, email, password string) (core.User, error) {
	if b, err := passwordBackend.VerifyUserPassword(db, email, password); err != nil {
		return core.User{}, err
	} else if !b {
		return core.User{}, ErrCredentialsInvalid
	}
	return core.UserByEmail(db, email)
}

func CreateAccessToken(db db.TxHandler, email, password string) (core.User, string, error) {
	if user, err := VerifyUserPassword(db, email, password); err != nil {
		return core.User{}, "", err
	} else if token, err := insertAccessToken(db, user.ID); err != nil {
		return core.User{}, "", err
	} else {
		return user, token, nil
	}
}

func ReadAccessToken(db db.Handler, accessToken string) (user core.User, err error) {
	const q = `SELECT t.expires, u.id, u.email, u.name, u.permissions, u.home FROM access_tokens t JOIN users u ON t.user_id = u.id WHERE t.id = $1; `
	row := db.QueryRow(q, accessToken)

	var expires pgtype.Timestamp
	err = row.Scan(&expires, &user.ID, &user.Email, &user.Name, &user.Permissions, &user.Home)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrCredentialsInvalid
		}
	} else if time.Now().After(expires.Time) {
		return core.User{}, ErrCredentialsInvalid
	}
	return
}

func CreateResetToken(db db.TxHandler, email string) (core.User, string, error) {
	if !passwordBackend.SupportsPasswordUpdate() {
		return core.User{}, "", errors.New("password update not supported")
	}
	user, err := core.UserByEmail(db, email)
	if err != nil {
		return core.User{}, "", err
	}

	if token, err := insertResetToken(db, user.ID); err != nil {
		return core.User{}, "", err
	} else {
		return user, token, nil
	}

}

func ResetUserPassword(db db.TxHandler, email, resetToken, password string) (core.User, string, error) {
	if !passwordBackend.SupportsPasswordUpdate() {
		return core.User{}, "", errors.New("password update not supported")
	}
	user, err := core.UserByEmail(db, email)
	if err != nil {
		return user, "", err
	}

	// UpdateUserPassword will ensure the password strength
	// Not incorrect to do this before token verification because we are in a transaction.
	// TODO: Are there perf implications for this in case of malicious actors?
	err = UpdateUserPassword(db, email, password)
	if err != nil {
		return core.User{}, "", err
	}

	const q = `DELETE FROM reset_tokens WHERE user_id = @user_id::INT AND token = @token::TEXT RETURNING expires`
	args := pgx.NamedArgs{
		"user_id": user.ID,
		"token":   resetToken,
		"expires": time.Now().Add(resetTokenDuration),
	}
	row := db.QueryRow(q, args)
	var expires pgtype.Timestamp
	if err := row.Scan(&expires); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrCredentialsInvalid
		}
		return core.User{}, "", err
	}
	if time.Now().After(expires.Time) {
		return core.User{}, "", ErrCredentialsInvalid
	}

	apiToken, err := insertAccessToken(db, user.ID)
	if err != nil {
		return core.User{}, "", err
	}
	return user, apiToken, nil
}

func UpdateUserPassword(db db.TxHandler, email, password string) error {
	if err := checkPasswordStrength(password); err != nil {
		return err
	}
	return passwordBackend.UpdateUserPassword(db, email, password)
}

func insertAccessToken(db db.TxHandler, userID int32) (string, error) {
	const q = `INSERT INTO access_tokens(id, expires, user_id) VALUES ($1::TEXT, NOW() + $2::INTERVAL, $3::INT)`

	token := generateRandomString(apiTokenLength)
	if _, err := db.Exec(q, token, accessTokenValidity, userID); err != nil {
		return "", err
	} else {
		return token, nil
	}
}

func insertResetToken(db db.TxHandler, userID int32) (string, error) {
	const q = `INSERT INTO reset_tokens(user_id, token, expires)
VALUES (@user_id::INT, @token::TEXT, @expires::TIMESTAMP)
ON CONFLICT(user_id) DO UPDATE SET token = @token::TEXT, expires = @expires::TIMESTAMP`
	token := generateRandomString(resetTokenLength)

	args := pgx.NamedArgs{
		"user_id": userID,
		"token":   token,
		"expires": time.Now().Add(resetTokenDuration),
	}
	if _, err := db.Exec(q, args); err != nil {
		return "", err
	}
	return token, nil
}

func generateRandomString(n int) string {
	b := make([]byte, n*3/4)
	rand.Read(b)
	return base64.URLEncoding.EncodeToString(b)
}
