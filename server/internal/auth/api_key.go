package auth

import (
	"errors"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func VerifyAPIKey(db db.Handler, apiKey string) (user core.User, err error) {
	const q = `SELECT k.expires, u.id, u.email, u.name, u.permissions, u.home FROM api_keys k JOIN users u ON k.user_id = u.id WHERE k.key = $1; `
	row := db.QueryRow(q, apiKey)

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

func insertAPIKey(db db.TxHandler, userID int32) (string, error) {
	const q = `INSERT INTO api_keys(key, expires, user_id) VALUES (@key::TEXT, @expires::TIMESTAMPTZ, @user_id::INT)`

	token := generateSecureKey(apiKeyLength)
	args := pgx.NamedArgs{
		"token":   generateSecureKey(apiKeyLength),
		"expires": time.Now().Add(apiKeyValidity),
		"user_id": userID,
	}
	if _, err := db.Exec(q, args); err != nil {
		return "", err
	} else {
		return token, nil
	}
}
