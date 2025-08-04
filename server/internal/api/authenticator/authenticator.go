package authenticator

import (
	"encoding/base64"
	"errors"
	"net/http"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
)

var errAuthRequired = core.NewError(http.StatusUnauthorized, "auth_required", "authorization required")
var errCredentialsInvalid = core.NewError(http.StatusUnauthorized, "credentials_invalid", "invalid credentials")

const keyAuth = "auth"

func GetAuth(c *gin.Context) *auth.Auth {
	val, ok := c.Get(keyAuth)
	if !ok {
		return nil
	}
	return val.(*auth.Auth)
}
func GetFileSystem(c *gin.Context) *core.FileSystem {
	return GetAuth(c).GetFileSystem(db.Get(c), pgtype.UUID{})
}

func Require(c *gin.Context) {
	if a, err := getAuth(c); err != nil {
		panic(err)
	} else {
		c.Set(keyAuth, a)
	}
}

func getAuth(c *gin.Context) (*auth.Auth, error) {
	db := db.Get(c.Request.Context())
	connectionDetails := auth.ConnectionDetails(
		c.RemoteIP(),
		c.Request.Header.Get("X-Device"),
		c.Request.Header.Get("User-Agent"),
	)
	if header := c.Request.Header.Get("Authorization"); header == "" {
		if cookie, err := c.Request.Cookie("api_token"); err == nil {
			encodedKey := cookie.Value
			if a, err := auth.ReadAPIToken(db, encodedKey, connectionDetails); err == nil {
				return a, nil
			} else {
				if errors.Is(err, auth.ErrCredentialsInvalid) {
					err = errCredentialsInvalid
				}
				return nil, err
			}
		} else if err != http.ErrNoCookie {
			return nil, err
		}
		return nil, errCredentialsInvalid
	} else if authHeader, ok := checkAuthHeader(header, "basic"); ok {
		if keyIDStr, keyStr, ok := decodeBasicAuth(authHeader); ok {
			var a *auth.Auth
			var err error

			if keyIDStr == "" {
				a, err = auth.ReadAPIToken(db, keyStr, connectionDetails)
			} else {
				a, err = auth.ReadAPIKey(db, keyIDStr, keyStr, connectionDetails)
			}

			if err == nil {
				return a, nil
			} else {
				if errors.Is(err, auth.ErrCredentialsInvalid) {
					err = errCredentialsInvalid
				}
				return nil, err
			}
		}
	} else if encodedKey, ok := checkAuthHeader(header, "bearer"); ok {
		if a, err := auth.ReadAPIToken(db, encodedKey, connectionDetails); err == nil {
			return a, nil
		} else {
			if errors.Is(err, auth.ErrCredentialsInvalid) {
				err = errCredentialsInvalid
			}
			return nil, err
		}
	}
	return nil, errCredentialsInvalid
}

func checkAuthHeader(header, prefix string) (string, bool) {
	prefix = strings.ToLower(prefix) + " "
	if len(header) < len(prefix) || !strings.EqualFold(strings.ToLower(header[:len(prefix)]), prefix) {
		return "", false
	}
	return header[len(prefix):], true
}

func decodeBasicAuth(auth string) (email, password string, ok bool) {
	c, err := base64.StdEncoding.DecodeString(auth)
	if err != nil {
		return "", "", false
	}
	cs := string(c)
	email, password, ok = strings.Cut(cs, ":")
	if !ok {
		return "", "", false
	}
	return email, password, true
}
