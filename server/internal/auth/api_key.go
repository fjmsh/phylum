package auth

import (
	"errors"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type Auth interface {
	UserID() int32
	UserPermissions() core.UserPermissions
	HasScope(scope string) bool
}

type auth struct {
	userID          int32
	userPermissions core.UserPermissions
	scopes          []string
}

func (a auth) UserID() int32 {
	return a.userID
}

func (a auth) UserPermissions() core.UserPermissions {
	return a.userPermissions
}

func (a auth) HasScope(scope string) bool {
	for _, s := range a.scopes {
		if s == "*" {
			return true
		}
	}

	return false
}

func VerifyAPIKey(db db.Handler, apiKey string) (Auth, error) {
	const q = `SELECT k.expires, u.id, u.permissions, k.scopes FROM api_keys k JOIN users u ON k.user_id = u.id WHERE k.key = $1; `
	row := db.QueryRow(q, apiKey)

	var expires pgtype.Timestamp
	var auth auth
	err := row.Scan(&expires, &auth.userID, &auth.userPermissions, &auth.scopes)
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
