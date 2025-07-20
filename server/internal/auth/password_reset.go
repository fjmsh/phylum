package auth

import (
	"crypto/sha256"
	"encoding/base32"
	"errors"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func CreateResetToken(db db.TxHandler, email string) (core.User, string, error) {
	if !passwordBackend.SupportsPasswordUpdate() {
		return core.User{}, "", errors.New("password update not supported")
	}
	email = strings.TrimSpace(strings.ToLower(email))
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

func ResetUserPassword(db db.TxHandler, email, resetToken, password string) (a Auth, apiToken string, err error) {
	if passwordBackend == nil || !passwordBackend.SupportsPasswordUpdate() {
		err = errors.New("password update not supported")
		return
	}
	user, err := core.UserByEmail(db, email)
	if err != nil {
		return
	}

	// UpdateUserPassword will ensure the password strength
	// Not incorrect to do this before token verification because we are in a transaction.
	// TODO: Are there perf implications for this in case of malicious actors?
	err = UpdateUserPassword(db, email, password)
	if err != nil {
		return
	}

	const q = `DELETE FROM reset_tokens WHERE user_id = @user_id::INT AND token_hash = @token_hash RETURNING expires`
	b, err := base32.StdEncoding.DecodeString(resetToken)
	if err != nil {
		return
	}
	hash := sha256.Sum256(b)
	args := pgx.NamedArgs{
		"user_id":    user.ID,
		"token_hash": hash[:],
	}
	row := db.QueryRow(q, args)
	var expires time.Time
	if err = row.Scan(&expires); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrTokenInvalid
		}
		return
	}
	if time.Now().After(expires) {
		err = ErrTokenInvalid
		return
	}

	a = auth{
		userID:          user.ID,
		homeID:          user.Home,
		userPermissions: user.Permissions,
		scopes:          []string{"*"},
	}
	_, _, apiToken, err = GenerateAPIKey(db, user.ID, pgtype.Timestamptz{}, "Login - Password Reset", []string{"*"})
	return
}

func VerifyAndChangeUserPassword(db db.Handler, email, oldPassword, newPassword string) error {
	if passwordBackend == nil || !passwordBackend.SupportsPasswordUpdate() {
		return errors.New("password update not supported")
	}
	if ok, err := passwordBackend.VerifyUserPassword(db, email, oldPassword); err != nil {
		return err
	} else if !ok {
		return ErrCredentialsInvalid
	}

	if err := checkPasswordStrength(newPassword); err != nil {
		return err
	}
	return passwordBackend.UpdateUserPassword(db, email, newPassword)
}

func UpdateUserPassword(db db.TxHandler, email, password string) error {
	if err := checkPasswordStrength(password); err != nil {
		return err
	}
	return passwordBackend.UpdateUserPassword(db, email, password)
}

func insertResetToken(db db.TxHandler, userID int32) (string, error) {
	const q = `INSERT INTO reset_tokens(user_id, token_hash, expires) VALUES (@user_id, @token_hash, @expires)
ON CONFLICT(user_id) DO UPDATE SET token_hash = @token_hash, expires = @expires`
	key := generateSecureKey(resetTokenLength)
	hash := sha256.Sum256(key)
	args := pgx.NamedArgs{
		"user_id":    userID,
		"token_hash": hash[:],
		"expires":    time.Now().Add(tokenValidity),
	}
	if _, err := db.Exec(q, args); err != nil {
		return "", err
	}
	return base32.StdEncoding.EncodeToString(key), nil
}
