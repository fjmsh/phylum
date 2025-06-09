package auth

import (
	"context"
	"errors"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/rand"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var Cfg Config

const accessTokenLength = 16
const resetTokenLength = 64
const resetTokenDuration = 10 * time.Minute

var accessTokenValidity = pgtype.Interval{
	Days:  30,
	Valid: true,
}

var ErrCredentialsInvalid = errors.New("invalid credentials")

func VerifyUserPassword(ctx context.Context, email, password string) (core.User, error) {
	if user, passwordHash, err := userPasswordHashByEmail(db.Get(ctx), email); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return core.User{}, ErrCredentialsInvalid
		}
		return core.User{}, err
	} else if passwordHash == "" {
		return core.User{}, ErrCredentialsInvalid
	} else {
		if b, err := crypt.Verify(password, passwordHash); err != nil {
			return core.User{}, err
		} else if !b {
			return core.User{}, ErrCredentialsInvalid
		}
		return user, nil
	}
}

func CreateAccessToken(ctx context.Context, user core.User) (string, error) {
	const q = `INSERT INTO access_tokens(id, expires, user_id) VALUES ($1::TEXT, NOW() + $2::INTERVAL, $3::INT)`
	id := rand.GenerateRandomString(accessTokenLength)
	if _, err := db.Get(ctx).Exec(q, id, accessTokenValidity, user.ID); err != nil {
		return "", err
	} else {
		return id, nil
	}
}

func ReadAccessToken(ctx context.Context, accessToken string) (user core.User, err error) {
	const q = `SELECT t.expires, u.id, u.email, u.name, u.permissions, u.home FROM access_tokens t JOIN users u ON t.user_id = u.id WHERE t.id = $1; `
	row := db.Get(ctx).QueryRow(q, accessToken)

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

func CreateResetToken(db db.Handler, user core.User) (string, error) {
	const q = `INSERT INTO reset_tokens(user_id, token, expires)
VALUES (@user_id::INT, @token::TEXT, @expires::TIMESTAMP)
ON CONFLICT(user_id) DO UPDATE SET token = @token::TEXT, expires = @expires::TIMESTAMP`
	token := rand.GenerateRandomString(resetTokenLength)

	args := pgx.NamedArgs{
		"user_id": user.ID,
		"token":   token,
		"expires": time.Now().Add(resetTokenDuration),
	}
	if _, err := db.Exec(q, args); err != nil {
		return "", err
	}
	return token, nil
}

func ResetUserPassword(d db.Handler, user core.User, token, password string) error {
	const q = `DELETE FROM reset_tokens WHERE user_id = @user_id::INT AND token = @token::TEXT RETURNING expires`
	args := pgx.NamedArgs{
		"user_id": user.ID,
		"token":   token,
		"expires": time.Now().Add(resetTokenDuration),
	}
	return d.RunInTx(func(d db.Handler) error {

		// UpdateUserPassword will ensure the password strength
		// Not incorrect to do this before token verification because we are in a transaction.
		// TODO: Are there perf implications for this in case of malicious actors?
		err := UpdateUserPassword(d, user, password)
		if err != nil {
			return err
		}
		row := d.QueryRow(q, args)
		var expires pgtype.Timestamp
		if err := row.Scan(&expires); err == nil {
			if time.Now().After(expires.Time) {
				return ErrCredentialsInvalid
			}
			return nil
		} else if errors.Is(err, pgx.ErrNoRows) {
			return ErrCredentialsInvalid
		} else {
			return err
		}
	})
}

func UpdateUserPassword(db db.Handler, user core.User, password string) error {
	if err := checkPasswordStrength(password); err != nil {
		return err
	}
	const q = "UPDATE users SET password_hash = $2::TEXT, modified = NOW() WHERE id = $1::INT"
	if hash, err := crypt.Generate(password); err != nil {
		return err
	} else {
		if _, err := db.Exec(q, user.ID, hash); err != nil {
			return err
		}
	}
	return nil
}

func userPasswordHashByEmail(db db.Handler, email string) (user core.User, passwordHash string, err error) {
	const q = "SELECT id, email, name, home, permissions, password_hash FROM users WHERE email = $1"
	row := db.QueryRow(q, strings.ToLower(email))
	err = row.Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&user.Home,
		&user.Permissions,
		&passwordHash)
	if errors.Is(err, pgx.ErrNoRows) {
		err = ErrCredentialsInvalid
	}
	return
}
