package auth

import (
	"errors"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

func CreateResetToken(db db.TxHandler, email string) (core.User, string, error) {
	if !passwordBackend.SupportsPasswordUpdate() {
		return core.User{}, "", errors.New("password update not supported")
	}
	email = strings.ToLower(email)
	user, err := core.UserByEmail(db, email)
	if errors.Is(err, core.ErrUserNotFound) && shouldAutoCreate(email) {
		user, err = core.CreateUser(db, email, "", false)
	}

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
	}
	row := db.QueryRow(q, args)
	var expires time.Time
	if err := row.Scan(&expires); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrCredentialsInvalid
		}
		return core.User{}, "", err
	}
	if time.Now().After(expires) {
		return core.User{}, "", ErrCredentialsInvalid
	}

	apiToken, err := insertAPIKey(db, user.ID, 0, "")
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

func insertResetToken(db db.TxHandler, userID int32) (string, error) {
	const q = `INSERT INTO reset_tokens(user_id, token, expires)
VALUES (@user_id::INT, @token::TEXT, @expires::TIMESTAMPTZ)
ON CONFLICT(user_id) DO UPDATE SET token = @token::TEXT, expires = @expires::TIMESTAMPTZ`
	token := generateSecureKey(resetTokenLength)

	args := pgx.NamedArgs{
		"user_id": userID,
		"token":   token,
		"expires": time.Now().Add(tokenValidity),
	}
	if _, err := db.Exec(q, args); err != nil {
		return "", err
	}
	return token, nil
}
