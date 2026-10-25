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
)

func (h *Handler) CreateResetToken(db db.TxHandler, email string) (core.User, string, error) {
	if !h.passwordBackend.SupportsPasswordUpdate() {
		return core.User{}, "", errors.New("password update not supported")
	}
	email = strings.TrimSpace(strings.ToLower(email))
	user, err := core.UserByEmail(db, email)
	if errors.Is(err, core.ErrUserNotFound) && h.passwordBackend.AutoCreateUsers() {
		user, err = core.CreateUser(db, email, "", false)
	}

	if err != nil {
		return core.User{}, "", err
	}

	if token, err := h.insertResetToken(db, user.ID); err != nil {
		return core.User{}, "", err
	} else {
		return user, token, nil
	}

}

func (h *Handler) ResetUserPassword(db db.TxHandler, email, resetToken, password string) (auth *Auth, apiToken string, err error) {
	if h.passwordBackend == nil || !h.passwordBackend.SupportsPasswordUpdate() {
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
	err = h.UpdateUserPassword(db, email, password)
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

	auth = NewLoginAuth(user)
	_, _, apiToken, err = GenerateAPIKey(db, auth, "Password Reset Login")
	return
}

func (h *Handler) VerifyAndChangeUserPassword(db db.Handler, email, oldPassword, newPassword string) error {
	if !h.PasswordBackendSupportsUpdate() {
		return errors.New("password update not supported")
	}
	if ok, err := h.passwordBackend.VerifyUserPassword(db, email, oldPassword); err != nil {
		return err
	} else if !ok {
		return ErrCredentialsInvalid
	}

	if err := h.checkPasswordStrength(newPassword); err != nil {
		return err
	}
	return h.passwordBackend.UpdateUserPassword(db, email, newPassword)
}

func (h *Handler) UpdateUserPassword(db db.TxHandler, email, password string) error {
	if !h.PasswordBackendSupportsUpdate() {
		return errors.New("password update not supported")
	}
	if err := h.checkPasswordStrength(password); err != nil {
		return err
	}
	return h.passwordBackend.UpdateUserPassword(db, email, password)
}

func (h *Handler) insertResetToken(db db.TxHandler, userID int32) (string, error) {
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
