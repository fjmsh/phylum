package auth

import (
	"crypto/sha256"
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/mileusna/useragent"
)

type APIKey struct {
	ID          string
	Created     time.Time
	Expires     pgtype.Timestamptz
	Description string
	Scopes      []string
	LastUsed    ConnectionInfo
}

type ConnectionInfo struct {
	Time   int64  `json:"timestamp"`
	IP     string `json:"ip"`
	Device string `json:"device"`
}

func ConnectionInfoJSON(ip, device, userAgent string) []byte {
	if device == "" {
		ua := useragent.Parse(userAgent)
		device = ua.Name
		if ua.Device != "" {
			device += " on " + ua.Device
		} else if ua.OS != "" {
			device += " on " + ua.OS
		}
	}
	info := ConnectionInfo{
		Time:   time.Now().Unix(),
		IP:     ip,
		Device: device,
	}
	b, _ := json.Marshal(info)
	return b
}

func ListAPIKeys(db db.Handler, userID int32, includeExpired bool) ([]APIKey, error) {
	q := "SELECT id, created, expires, description, scopes, last_used FROM api_keys WHERE user_id = $1"
	if !includeExpired {
		q += " AND (expires IS NULL OR expires > current_timestamp)"
	}
	q += " ORDER BY id DESC"
	if rows, err := db.Query(q, userID); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanAPIKey)
	}
}

func RevokeAPIKey(db db.Handler, userID int32, keyIDStr string, delete bool) error {
	const qUpdate = "UPDATE api_keys SET expires = CURRENT_TIMESTAMP WHERE id = $2 AND user_id = $1"
	const qDelete = "DELETE FROM api_keys WHERE id = $2 AND user_id = $1"
	q := qUpdate
	if delete {
		q = qDelete
	}
	if keyID, err := uuid.Parse(keyIDStr); err != nil {
		return core.NewError(http.StatusBadRequest, "key_not_found", "key not found")
	} else if tag, err := db.Exec(q, userID, keyID); err != nil {
		return err
	} else if tag.RowsAffected() == 0 {
		return core.NewError(http.StatusBadRequest, "key_not_found", "key not found")
	}
	return nil
}

func UpdateAPIKeyDescription(db db.Handler, userID int32, keyIDStr string, description string) error {
	const q = "UPDATE api_keys SET description = $3 WHERE id = $2 AND user_id = $1"
	if keyID, err := uuid.Parse(keyIDStr); err != nil {
		return core.NewError(http.StatusBadRequest, "key_not_found", "key not found")
	} else if tag, err := db.Exec(q, userID, keyID, description); err != nil {
		return err
	} else if tag.RowsAffected() == 0 {
		return core.NewError(http.StatusBadRequest, "key_not_found", "key not found")
	}
	return nil
}

func scanAPIKey(row pgx.CollectableRow) (APIKey, error) {
	var apiKey APIKey
	var id uuid.UUID
	var lastUsed []byte
	err := row.Scan(
		&id,
		&apiKey.Created,
		&apiKey.Expires,
		&apiKey.Description,
		&apiKey.Scopes,
		&lastUsed,
	)
	if err == nil {
		apiKey.ID = id.String()
		if lastUsed != nil {
			err = json.Unmarshal(lastUsed, &apiKey.LastUsed)
		}
	}
	return apiKey, err
}

func ReadAPIToken(db db.Handler, encodedKey string, connectionInfo []byte) (*Auth, error) {
	if b, err := b64Encoder.DecodeString(encodedKey); err != nil {
		return nil, ErrCredentialsInvalid
	} else if len(b) < 16 {
		return nil, ErrCredentialsInvalid
	} else {
		keyID, _ := uuid.FromBytes(b[:16])
		return readAPIKey(db, keyID, b[16:], connectionInfo)
	}
}

func ReadAPIKey(db db.Handler, keyIDStr, keyStr string, connectionInfo []byte) (*Auth, error) {
	if keyID, err := uuid.Parse(keyIDStr); err != nil {
		return nil, err
	} else if key, err := b32Encoder.DecodeString(keyStr); err != nil {
		return nil, err
	} else {
		return readAPIKey(db, keyID, key, connectionInfo)
	}
}

func readAPIKey(db db.Handler, keyID uuid.UUID, key []byte, connectionInfo []byte) (auth *Auth, err error) {
	const q = `WITH cte(id) AS (
	UPDATE api_keys SET last_used = $3
	WHERE id = $1 AND hash = $2 
	RETURNING id, user_id, expires, scopes
) SELECT k.expires, k.user_id, k.scopes, u.permissions, u.home FROM cte k
JOIN users u ON k.user_id = u.id`
	hash := sha256.Sum256(key)
	row := db.QueryRow(q, keyID, hash[:], connectionInfo)

	auth = new(Auth)
	err = row.Scan(&auth.expires, &auth.userID, &auth.scopes, &auth.userPermissions, &auth.homeID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrCredentialsInvalid
		}
	} else if auth.expires.Valid && time.Now().After(auth.expires.Time) {
		err = ErrCredentialsInvalid
	}
	return
}

func GenerateAPIKey(db db.Handler, auth *Auth, description string) (string, string, string, error) {
	const q = `INSERT INTO api_keys(id, expires, user_id, hash, description, scopes) VALUES (@id, @expires, @user_id, @hash, @description, @scopes)`

	id, _ := uuid.NewV7()
	key := generateSecureKey(apiKeyLength)
	hash := sha256.Sum256(key)
	args := pgx.NamedArgs{
		"id":          id,
		"expires":     auth.expires,
		"user_id":     auth.userID,
		"hash":        hash[:],
		"description": description,
		"scopes":      auth.scopes,
	}

	if _, err := db.Exec(q, args); err != nil {
		return "", "", "", err
	}
	return id.String(), b32Encoder.EncodeToString(key), b64Encoder.EncodeToString(append(id[:], key...)), nil
}
