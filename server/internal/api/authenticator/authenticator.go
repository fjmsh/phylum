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
)

var errAuthRequired = core.NewError(http.StatusUnauthorized, "auth_required", "authorization required")
var errCredentialsInvalid = core.NewError(http.StatusUnauthorized, "credentials_invalid", "invalid credentials")

const keyAuth = "auth"

func GetAuth(c *gin.Context) auth.Auth {
	val, ok := c.Get(keyAuth)
	if !ok {
		return nil
	}
	return val.(auth.Auth)
}

func GetFileSystem(c *gin.Context) *core.FileSystem {
	user := GetAuth(c)
	return user.OpenFileSystem(db.Get(c.Request.Context()))
}

func Require(c *gin.Context) {
	if a, err := getAuth(c); err != nil {
		panic(err)
	} else {
		c.Set(keyAuth, a)
	}
}

func getAuth(c *gin.Context) (auth.Auth, error) {
	db := db.Get(c.Request.Context())
	if header := c.Request.Header.Get("Authorization"); header == "" {
		if cookie, err := c.Request.Cookie("api_key"); err == nil {
			apiKey := cookie.Value
			if a, err := auth.VerifyAPIKey(db, apiKey); err == nil {
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
		return nil, errAuthRequired
	} else if authHeader, ok := checkAuthHeader(header, "basic"); ok {
		if email, password, ok := decodeBasicAuth(authHeader); ok {
			if a, err := auth.VerifyUserPassword(db, email, password); err == nil {
				return a, nil
			} else {
				if errors.Is(err, auth.ErrCredentialsInvalid) {
					err = errCredentialsInvalid
				}
				return nil, err
			}
		}
	} else if apiKey, ok := checkAuthHeader(header, "api-key"); ok {
		if a, err := auth.VerifyAPIKey(db, apiKey); err == nil {
			return a, nil
		} else {
			if errors.Is(err, auth.ErrCredentialsInvalid) {
				err = errCredentialsInvalid
			}
			return nil, err
		}
	}
	return nil, errAuthRequired
}

func checkAuthHeader(header, prefix string) (string, bool) {
	prefix = prefix + " "
	if len(header) < len(prefix) || !strings.EqualFold(header[:len(prefix)], prefix) {
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
