package auth

import (
	"errors"
	"net/url"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/auth/openid"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

const openidLoginSessionIDLength = 32

type OpenIDClientType uint8

const (
	OpenIDClientNone OpenIDClientType = iota
	OpenIDClientWeb
	OpenIDClientNative
)

func OpenIDStart(db db.Handler, providerName, redirectURI string, clientType OpenIDClientType) (string, error) {
	if clientID, endpoint, err := openid.GetProviderDetails(providerName); err != nil {
		return "", err
	} else {
		sessionID := generateRandomString(openidLoginSessionIDLength)
		_, err := db.Exec("INSERT INTO openid_sessions(id, provider, client_type) VALUES ($1, $2, $3)", sessionID, providerName, clientType)
		if err != nil {
			return "", errors.New("failed to insert openid session: " + err.Error())
		}
		authURL, err := url.Parse(endpoint)
		if err != nil {
			return "", errors.New("failed to parse authoriation endpoint: " + err.Error())
		}
		q := url.Values{}
		q.Add("client_id", clientID)
		q.Add("response_type", "code")
		q.Add("scope", "openid email profile")
		q.Add("state", sessionID)
		q.Add("redirect_uri", redirectURI)
		authURL.RawQuery = q.Encode()
		return authURL.String(), nil
	}
}

func OpenIDValidateAuthCode(d db.Handler, sessionID, authCode, redirecURI string) (OpenIDClientType, error) {
	row := d.QueryRow("SELECT provider, client_type FROM openid_sessions WHERE id = $1 AND user_id IS NULL", sessionID)
	var providerName string
	var clientType OpenIDClientType
	if err := row.Scan(&providerName, &clientType); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = errors.New("state token invalid")
		}
		return OpenIDClientNone, err
	} else if idToken, err := openid.GetIDToken(providerName, authCode, redirecURI); err != nil {
		return OpenIDClientNone, err
	} else {
		user, err := core.UserByEmail(d, idToken.Email)
		err = d.RunInTx(func(db db.TxHandler) error {
			if errors.Is(err, core.ErrUserNotFound) {
				for _, domain := range cfg.AutoCreateDomains {
					if strings.HasSuffix(strings.ToLower(idToken.Email), "@"+strings.ToLower(domain)) {
						user, err = core.CreateUser(db, idToken.Email, idToken.FullName, false)
					}
				}
			}
			if err != nil {
				return err
			}
			_, err = db.Exec("UPDATE openid_sessions SET user_id = $2 WHERE id = $1", sessionID, user.ID)
			return err
		})

		if err != nil {
			// This session ID is no longer valid, since we've already used the auth code once
			d.Exec("DELETE FROM openid_sessions WHERE id = $1", sessionID)
			return OpenIDClientNone, err
		}
		return clientType, nil
	}
}

func PerformOpenIDLogin(db db.TxHandler, sessionID string) (core.User, string, error) {
	row := db.QueryRow("DELETE FROM openid_sessions WHERE id = $1 AND user_id IS NOT NULL RETURNING user_id", sessionID)
	var userID int32
	if err := row.Scan(&userID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = errors.New("state token invalid")
		}
		return core.User{}, "", err
	} else if user, err := core.UserByID(db, userID); err != nil {
		return core.User{}, "", err
	} else if token, err := insertAccessToken(db, userID); err != nil {
		return core.User{}, "", err
	} else {
		return user, token, err
	}
}
