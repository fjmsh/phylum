package auth

import (
	"crypto/sha256"
	"errors"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func ReadAPIKey(db db.Handler, keyID uuid.UUID, key string) (Auth, error) {
	const q = `SELECT k.expires, u.id, u.permissions, u.home, k.scopes FROM api_keys k JOIN users u ON k.user_id = u.id WHERE k.id = $1 AND k.hash = $2`
	hash := sha256.Sum256([]byte(key))
	row := db.QueryRow(q, keyID, hash[:])

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

func GenerateAPIKey(db db.TxHandler, userID int32, validity time.Duration, description string, scopes []string) (uuid.UUID, string, error) {
	const q = `INSERT INTO api_keys(id, expires, user_id, hash, description, scopes) VALUES (@id, @expires, @user_id, @hash, @description, @scopes)`

	id, _ := uuid.NewV7()
	key := generateSecureKey(apiKeyLength)
	expires := pgtype.Timestamp{}
	if validity != 0 {
		expires.Valid = true
		expires.Time = time.Now().Add(validity)
	}
	hash := sha256.Sum256([]byte(key))
	args := pgx.NamedArgs{
		"id":          id,
		"expires":     expires,
		"user_id":     userID,
		"hash":        hash[:],
		"description": description,
		"scopes":      scopes,
	}
	if _, err := db.Exec(q, args); err != nil {
		return uuid.Nil, "", err
	} else {
		return id, key, nil
	}
}
