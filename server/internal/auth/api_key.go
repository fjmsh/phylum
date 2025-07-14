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

type APIKey struct {
	ID          uuid.UUID
	Created     time.Time
	Expires     pgtype.Timestamptz
	Description string
	Scopes      []string
}

func ListAPIKeys(db db.Handler, userID int32) ([]APIKey, error) {
	const q = `SELECT id, created, expires, description, scopes FROM api_keys WHERE user_id = $1`
	if rows, err := db.Query(q, userID); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanAPIKey)
	}
}

func scanAPIKey(row pgx.CollectableRow) (APIKey, error) {
	var apiKey APIKey
	return apiKey, row.Scan(
		&apiKey.ID,
		&apiKey.Created,
		&apiKey.Expires,
		&apiKey.Description,
		&apiKey.Scopes,
	)
}

func ReadAPIToken(db db.Handler, encodedKey string) (Auth, error) {
	if b, err := b64Encoder.DecodeString(encodedKey); err != nil {
		return nil, ErrCredentialsInvalid
	} else if len(b) < 16 {
		return nil, ErrCredentialsInvalid
	} else {
		keyID, _ := uuid.FromBytes(b[:16])
		return readAPIKey(db, keyID, b[16:])
	}
}

func GenerateAPIToken(db db.TxHandler, userID int32, validity time.Duration, description string, scopes []string) (string, error) {
	if id, key, err := generateAPIKey(db, userID, validity, description, scopes); err != nil {
		return "", err
	} else {
		return b64Encoder.EncodeToString(append(id[:], key...)), nil
	}
}

func GenerateAPIKey(db db.TxHandler, userID int32, validity time.Duration, description string, scopes []string) (id, key string, err error) {
	if id, key, err := generateAPIKey(db, userID, validity, description, scopes); err != nil {
		return "", "", err
	} else {
		return b64Encoder.EncodeToString(id[:]), b32Encoder.EncodeToString(key), nil
	}
}

func ReadAPIKey(db db.Handler, keyIDStr, keyStr string) (Auth, error) {
	if b, err := b64Encoder.DecodeString(keyIDStr); err != nil {
		return nil, err
	} else if keyID, err := uuid.FromBytes(b); err != nil {
		return nil, err
	} else if key, err := b32Encoder.DecodeString(keyStr); err != nil {
		return nil, err
	} else {
		return readAPIKey(db, keyID, key)
	}
}

func readAPIKey(db db.Handler, keyID uuid.UUID, key []byte) (Auth, error) {
	const q = `SELECT k.expires, u.id, u.permissions, u.home, k.scopes FROM api_keys k JOIN users u ON k.user_id = u.id WHERE k.id = $1 AND k.hash = $2`
	hash := sha256.Sum256(key)
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

func generateAPIKey(db db.TxHandler, userID int32, validity time.Duration, description string, scopes []string) (id uuid.UUID, key []byte, err error) {
	const q = `INSERT INTO api_keys(id, expires, user_id, hash, description, scopes) VALUES (@id, @expires, @user_id, @hash, @description, @scopes)`

	id, _ = uuid.NewV7()
	key = generateSecureKey(apiKeyLength)
	expires := pgtype.Timestamp{}
	if validity != 0 {
		expires.Valid = true
		expires.Time = time.Now().Add(validity)
	}
	hash := sha256.Sum256(key)
	args := pgx.NamedArgs{
		"id":          id,
		"expires":     expires,
		"user_id":     userID,
		"hash":        hash[:],
		"description": description,
		"scopes":      scopes,
	}
	_, err = db.Exec(q, args)
	return
}
