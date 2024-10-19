package auth

import (
	"encoding/base64"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/errors"
)

type authHeaderType = int

const (
	authHeaderNone    = -1
	authHeaderUnknown = 0
	authHeaderBasic   = 1
	authHeaderBearer  = 2
)

var (
	errAuthRequired = errors.NewError(http.StatusUnauthorized, "auth_required", "authorization required")
)

func CreateApiAuthHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		if user, err := extractUserDetails(a, c); err != nil {
			panic(err)
		} else {
			c.Set(keyUser, user)
			c.Set(keyFileSystem, a.OpenFileSystem(ctx, user))
		}
	}
}

func extractUserDetails(a *app.App, c *gin.Context) (app.User, error) {
	if header := c.Request.Header.Get("Authorization"); header == "" {
		return app.User{}, errAuthRequired
	} else if auth, ok := checkAuthHeader(header, "basic"); ok {
		if username, password, ok := decodeBasicAuth(auth); ok {
			if user, err := a.VerifyUserPassword(c.Request.Context(), username, password); err == nil {
				return user, nil
			} else {
				return app.User{}, err
			}
		}
	} else if token, ok := checkAuthHeader(header, "bearer"); ok {
		if user, err := a.ReadAccessToken(c.Request.Context(), token); err == nil {
			return user, nil
		} else {
			return app.User{}, err
		}
	}
	return app.User{}, errAuthRequired
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
