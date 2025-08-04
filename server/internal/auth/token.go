package auth

import (
	"crypto/sha256"
	"errors"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/openid"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func PerformTokenLogin(db db.TxHandler, encodedToken string) (*Auth, string, error) {
	if b, err := b32Encoder.DecodeString(encodedToken); err != nil {
		return nil, "", ErrCredentialsInvalid
	} else if len(b) < 16 {
		return nil, "", ErrCredentialsInvalid
	} else {
		tokenID, _ := uuid.FromBytes(b[:16])
		return performTokenLogin(db, tokenID, b[16:])
	}
}

func CreateLoginToken(db db.TxHandler, email string) (core.User, string, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	user, err := core.UserByEmail(db, email)
	if errors.Is(err, core.ErrUserNotFound) && shouldAutoCreate(email) {
		user, err = core.CreateUser(db, email, "", false)
	}

	if err != nil {
		return core.User{}, "", err
	}

	tokenID, _ := uuid.NewV7()
	token := generateSecureKey(loginTokenLength)
	hash := sha256.Sum256(token)
	args := pgx.NamedArgs{
		"user_id":    user.ID,
		"token_id":   tokenID,
		"expires":    time.Now().Add(tokenValidity),
		"token_hash": hash[:],
	}

	const q = `INSERT INTO pending_logins(user_id, token_id, expires, token_hash) VALUES (@user_id, @token_id, @expires, @token_hash)`
	_, err = db.Exec(q, args)
	if err != nil {
		return core.User{}, "", errors.New("failed to create login token: " + err.Error())
	}
	return user, b32Encoder.EncodeToString(append(tokenID[:], token...)), nil
}

func performTokenLogin(db db.TxHandler, tokenID uuid.UUID, token []byte) (auth *Auth, apiToken string, err error) {
	const q = "DELETE FROM pending_logins WHERE token_id = @token_id AND token_hash = @token_hash AND user_id IS NOT NULL RETURNING user_id, expires, oidc_provider"
	hash := sha256.Sum256([]byte(token))
	args := pgx.NamedArgs{
		"token_id":   tokenID,
		"token_hash": hash[:],
	}

	var user core.User
	var userID int32
	var expires time.Time
	var oidcProvider string
	row := db.QueryRow(q, args)
	if err = row.Scan(&userID, &expires, &oidcProvider); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrTokenInvalid
		}
		return
	} else if expires.Before(time.Now()) {
		err = ErrTokenInvalid
		return
	} else if user, err = core.UserByID(db, userID); err != nil {
		return
	} else {
		auth = NewSUAuth(user)
		description := "Magic Link Login"
		if oidcProvider != "" {
			var p string
			if p, err = openid.GetProviderName(oidcProvider); err != nil {
				return
			} else {
				description = "OAuth Login (via " + p + ")"
			}
		}
		_, _, apiToken, err = GenerateAPIKey(db, auth, description)
		return
	}
}
