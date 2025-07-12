package auth

import (
	"errors"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func ReadAPIKey(db db.Handler, apiKey string) (Auth, error) {
	const q = `SELECT k.expires, u.id, u.permissions, u.home, k.scopes FROM api_keys k JOIN users u ON k.user_id = u.id WHERE k.key = $1; `
	row := db.QueryRow(q, apiKey)

	var expires pgtype.Timestamp
	var auth auth
	err := row.Scan(&expires, &auth.userID, &auth.userPermissions, &auth.homeID, &auth.scopes)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrCredentialsInvalid
		}
		return nil, err
	} else if expires.Valid && time.Now().After(expires.Time) {
		return nil, ErrCredentialsInvalid
	}
	return auth, nil
}

func insertAPIKey(db db.TxHandler, userID int32, validity time.Duration, keyName string, scopes []string) (string, error) {
	const q = `INSERT INTO api_keys(key, expires, user_id, name, scopes) VALUES (@key::TEXT, @expires, @user_id::INT, NULLIF(@key_name, ''), @scopes::TEXT[])`

	key := generateSecureKey(apiKeyLength)
	expires := pgtype.Timestamp{}
	if validity != 0 {
		expires.Valid = true
		expires.Time = time.Now().Add(validity)
	}
	args := pgx.NamedArgs{
		"key":      key,
		"expires":  expires,
		"user_id":  userID,
		"key_name": keyName,
		"scopes":   scopes,
	}
	if _, err := db.Exec(q, args); err != nil {
		return "", err
	} else {
		return key, nil
	}
}
