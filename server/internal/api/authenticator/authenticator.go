package authenticator

import (
	"encoding/base64"
	"net/http"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

var errAuthRequired = core.NewError(http.StatusUnauthorized, "auth_required", "authorization required")

const keyUser = "user"

func GetUser(c *gin.Context) core.User {
	val, ok := c.Get(keyUser)
	if !ok {
		return core.User{}
	}
	return val.(core.User)
}

func GetFileSystem(c *gin.Context) *core.FileSystem {
	user := GetUser(c)
	return user.OpenFileSystem(db.Get(c.Request.Context()))
}

func Require(c *gin.Context) {
	if u, err := extractUserDetails(c); err != nil {
		panic(err)
	} else {
		c.Set(keyUser, u)
	}
}

func extractUserDetails(c *gin.Context) (core.User, error) {
	db := db.Get(c.Request.Context())
	if header := c.Request.Header.Get("Authorization"); header == "" {
		if cookie, err := c.Request.Cookie("auth_token"); err == nil {
			token := cookie.Value
			if u, err := auth.ReadAccessToken(db, token); err == nil {
				return u, nil
			} else {
				return core.User{}, err
			}
		} else if err != http.ErrNoCookie {
			return core.User{}, err
		}
		return core.User{}, errAuthRequired
	} else if authHeader, ok := checkAuthHeader(header, "basic"); ok {
		if email, password, ok := decodeBasicAuth(authHeader); ok {
			if u, err := auth.VerifyUserPassword(db, email, password); err == nil {
				return u, nil
			} else {
				return core.User{}, err
			}
		}
	} else if token, ok := checkAuthHeader(header, "bearer"); ok {
		if u, err := auth.ReadAccessToken(db, token); err == nil {
			return u, nil
		} else {
			return core.User{}, err
		}
	}
	return core.User{}, errAuthRequired
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
