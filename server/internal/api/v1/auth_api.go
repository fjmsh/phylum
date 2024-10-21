package apiv1

import (
	"encoding/base64"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/user"
)

type authHeaderType = int

const (
	authHeaderNone    = -1
	authHeaderUnknown = 0
	authHeaderBasic   = 1
	authHeaderBearer  = 2
)

func CreateApiAuthHandler(a app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		if user, err := extractUserDetails(a, c); err != nil {
			panic(err)
		} else {
			auth.Set(c, user, a.OpenFileSystem(ctx, user))
		}
	}
}

func extractUserDetails(a app.App, c *gin.Context) (user.User, error) {
	userManager := a.OpenUserManager(c.Request.Context())
	if header := c.Request.Header.Get("Authorization"); header == "" {
		return user.User{}, auth.ErrRequired
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
	return user.User{}, auth.ErrRequired
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
