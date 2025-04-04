package auth

import (
	"encoding/base64"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/user"
)

type authHeaderType = int

const (
	authHeaderNone    = -1
	authHeaderUnknown = 0
	authHeaderBasic   = 1
	authHeaderBearer  = 2
)

var errAuthRequired = errors.NewError(http.StatusUnauthorized, "auth_required", "authorization required")

func CreateHandler() func(c *gin.Context) {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		if u, err := extractUserDetails(c); err != nil {
			panic(err)
		} else {
			c.Set(keyUser, u)
			c.Set(keyFileSystem, u.OpenFileSystem(ctx))
		}
	}
}

func extractUserDetails(c *gin.Context) (user.User, error) {
	userManager := user.ManagerFromContext(c.Request.Context())
	if header := c.Request.Header.Get("Authorization"); header == "" {
		return user.User{}, errAuthRequired
	} else if auth, ok := checkAuthHeader(header, "basic"); ok {
		if username, password, ok := decodeBasicAuth(auth); ok {
			if u, err := userManager.VerifyUserPassword(username, password); err == nil {
				return u, nil
			} else {
				return user.User{}, err
			}
		}
	} else if token, ok := checkAuthHeader(header, "bearer"); ok {
		if u, err := userManager.ReadAccessToken(token); err == nil {
			return u, nil
		} else {
			return user.User{}, err
		}
	}
	return user.User{}, errAuthRequired
}

func checkAuthHeader(header, prefix string) (string, bool) {
	prefix = prefix + " "
	if len(header) < len(prefix) || !strings.EqualFold(header[:len(prefix)], prefix) {
		return "", false
	}
	return header[len(prefix):], true
}

func decodeBasicAuth(auth string) (username, password string, ok bool) {
	c, err := base64.StdEncoding.DecodeString(auth)
	if err != nil {
		return "", "", false
	}
	cs := string(c)
	username, password, ok = strings.Cut(cs, ":")
	if !ok {
		return "", "", false
	}
	return username, password, true
}
