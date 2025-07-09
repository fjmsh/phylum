package auth

import (
	"errors"
	"net/url"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/openid"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

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
		token := generateSecureKey(loginTokenLength)
		args := pgx.NamedArgs{
			"token":            token,
			"expires":          time.Now().Add(tokenValidity),
			"oidc_provider":    providerName,
			"oidc_client_type": clientType,
		}
		const query = `INSERT INTO pending_logins(token, expires, oidc_provider, oidc_client_type)
VALUES (@token::TEXT, @expires::TIMESTAMPTZ, @oidc_provider::TEXT, @oidc_client_type::SMALLINT)`
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
		q.Add("state", token)
		q.Add("redirect_uri", redirectURI)
		authURL.RawQuery = q.Encode()
		return authURL.String(), nil
	}
}

func OpenIDValidateAuthCode(d db.Handler, token, authCode, redirecURI string) (OpenIDClientType, error) {
	row := d.QueryRow("SELECT oidc_provider, oidc_client_type FROM pending_logins WHERE token = $1 AND user_id IS NULL AND expires >= NOW()", token)
	var providerName string
	var clientType OpenIDClientType
	if err := row.Scan(&providerName, &clientType); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = errors.New("login token invalid")
		}
		return OpenIDClientNone, err
	} else if idToken, err := openid.GetIDToken(providerName, authCode, redirecURI); err != nil {
		return OpenIDClientNone, err
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
			_, err = db.Exec("UPDATE pending_logins SET user_id = $2 WHERE token = $1", token, user.ID)
			return err
		})

		if err != nil {
			// This session ID is no longer valid, since we've already used the auth code once
			d.Exec("DELETE FROM pending_logins WHERE token = $1", token)
			return OpenIDClientNone, err
		}
		return clientType, nil
	}
}
