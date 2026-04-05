package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"net/url"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/openid"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type OpenIDClientType uint8

const (
	OpenIDClientNone OpenIDClientType = iota
	OpenIDClientWeb
	OpenIDClientNative
	OpenIDClientLoopback
)

func OpenIDStart(db db.Handler, providerName, redirectURI string, clientType OpenIDClientType, loopbackPort int) (string, error) {
	if clientID, endpoint, err := openid.GetClientDetails(providerName); err != nil {
		return "", err
	} else {
		codeVerifier, codeChallenge := generateOpenIDPKCEChallenge()
		tokenID, _ := uuid.NewV7()
		token := generateSecureKey(loginTokenLength)
		hash := sha256.Sum256(token)

		args := pgx.NamedArgs{
			"token_id":           tokenID,
			"expires":            time.Now().Add(tokenValidity),
			"token_hash":         hash[:],
			"oidc_provider":      providerName,
			"oidc_client_type":   clientType,
			"loopback_port":      loopbackPort,
			"oidc_code_verifier": codeVerifier,
		}
		const query = `INSERT INTO pending_logins(token_id, expires, token_hash, oidc_provider, oidc_client_type, loopback_port, oidc_code_verifier)
VALUES (@token_id, @expires, @token_hash, @oidc_provider, @oidc_client_type, @loopback_port, @oidc_code_verifier)`
		_, err := db.Exec(query, args)
		if err != nil {
			return "", errors.New("failed to create login token: " + err.Error())
		}
		authURL, err := url.Parse(endpoint)
		if err != nil {
			return "", errors.New("failed to parse authorization endpoint: " + err.Error())
		}

		q := url.Values{}
		q.Add("client_id", clientID)
		q.Add("response_type", "code")
		q.Add("scope", "openid email profile")
		q.Add("state", b32Encoder.EncodeToString(append(tokenID[:], token...)))
		q.Add("redirect_uri", redirectURI)
		q.Add("code_challenge", codeChallenge)
		q.Add("code_challenge_method", "S256")
		authURL.RawQuery = q.Encode()
		return authURL.String(), nil
	}
}

func OpenIDValidateAuthCode(d db.Handler, state, authCode, redirectURI string) (OpenIDClientType, int, error) {
	const q = "SELECT oidc_provider, oidc_client_type, loopback_port, oidc_code_verifier FROM pending_logins WHERE token_id = token_id AND token_hash = @token_hash AND user_id IS NULL AND expires >= NOW()"

	var tokenID uuid.UUID
	var tokenHash []byte
	if b, err := b32Encoder.DecodeString(state); err != nil {
		return OpenIDClientNone, 0, ErrTokenInvalid
	} else if len(b) < 16 {
		return OpenIDClientNone, 0, ErrTokenInvalid
	} else {
		tokenID, _ = uuid.FromBytes(b[:16])
		hash := sha256.Sum256(b[16:])
		tokenHash = hash[:]
	}
	args := pgx.NamedArgs{
		"token_id":   tokenID,
		"token_hash": tokenHash,
	}

	row := d.QueryRow(q, args)
	var providerName string
	var clientType OpenIDClientType
	var loopbackPort int
	var codeVerifier string
	if err := row.Scan(&providerName, &clientType, &loopbackPort, &codeVerifier); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrTokenInvalid
		}
		return OpenIDClientNone, 0, err
	} else if idToken, err := openid.GetUserInfo(providerName, authCode, redirectURI, codeVerifier); err != nil {
		return OpenIDClientNone, 0, err
	} else {
		email := strings.ToLower(idToken.Email)
		user, err := core.UserByEmail(d, email)
		err = d.RunInTx(func(db db.TxHandler) error {
			if errors.Is(err, core.ErrUserNotFound) && shouldAutoCreate(email) {
				name := idToken.Name
				if name == "" {
					name = idToken.GivenName + " " + idToken.FamilyName
				}
				user, err = core.CreateUser(db, idToken.Email, name, false)
			}
			if err != nil {
				return err
			}
			_, err = db.Exec("UPDATE pending_logins SET user_id = $2 WHERE token_id = $1", tokenID, user.ID)
			return err
		})

		if err != nil {
			// This session ID is no longer valid, since we've already used the auth code once
			d.Exec("DELETE FROM pending_logins WHERE token_id = $1", tokenID)
			return OpenIDClientNone, 0, err
		}
		return clientType, loopbackPort, nil
	}
}

func generateOpenIDPKCEChallenge() (string, string) {
	verifierLen := 64
	numBytes := verifierLen * 3 / 4
	b := make([]byte, numBytes)
	rand.Read(b)
	codeVerifier := base64.RawURLEncoding.EncodeToString(b)
	if len(codeVerifier) > 128 {
		codeVerifier = codeVerifier[:128]
	}

	hash := sha256.Sum256([]byte(codeVerifier))
	codeChallenge := base64.RawURLEncoding.EncodeToString(hash[:])
	return codeVerifier, codeChallenge
}
