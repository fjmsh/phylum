package auth

import (
	"crypto/sha256"
	"errors"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func PerformTokenLogin(db db.TxHandler, encodedToken string) (Auth, string, error) {
	if b, err := b32Encoder.DecodeString(encodedToken); err != nil {
		return nil, "", ErrCredentialsInvalid
	} else if len(b) < 16 {
		return nil, "", ErrCredentialsInvalid
	} else {
		tokenID, _ := uuid.FromBytes(b[:16])
		return performTokenLogin(db, tokenID, b[16:])
	}
}

func performTokenLogin(db db.TxHandler, tokenID uuid.UUID, token []byte) (a Auth, key string, err error) {
	const q = "DELETE FROM pending_logins WHERE token_id = @token_id AND token_hash = @token_hash AND user_id IS NOT NULL RETURNING user_id, expires"
	hash := sha256.Sum256([]byte(token))
	args := pgx.NamedArgs{
		"token_id":   tokenID,
		"token_hash": hash[:],
	}

	var user core.User
	var userID int32
	var expires time.Time
	row := db.QueryRow(q, args)
	if err = row.Scan(&userID, &expires); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrTokenInvalid
		}
		return
	} else if expires.Before(time.Now()) {
		err = ErrTokenInvalid
		return
	} else if user, err = core.UserByID(db, userID); err != nil {
		return
	} else if key, err = GenerateAPIToken(db, userID, 0, "", []string{"*"}); err != nil {
		return
	} else {
		a = auth{
			userID:          user.ID,
			homeID:          user.Home,
			userPermissions: user.Permissions,
			scopes:          []string{"*"},
		}
		return
	}
}
