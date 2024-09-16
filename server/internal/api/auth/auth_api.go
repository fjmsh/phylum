package auth

import (
	"encoding/base64"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/core"
)

type authHeaderType = int

const (
	authHeaderNone    = -1
	authHeaderUnknown = 0
	authHeaderBasic   = 1
	authHeaderBearer  = 2
)

const errCodeAuthRequred = "auth_required"
const errCodeCredentialsInvalid = "credentials_invalid"

func CreateApiAuthHandler(a *core.App) func(c *gin.Context) {
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

func extractUserDetails(a *core.App, c *gin.Context) (core.User, error) {
	if header := c.Request.Header.Get("Authorization"); header == "" {
		return core.User{}, errors.New(http.StatusUnauthorized, errCodeAuthRequred, "Authorization Required")
	} else if auth, ok := checkAuthHeader(header, "basic"); ok {
		if username, password, ok := decodeBasicAuth(auth); ok {
			if user, err := a.VerifyUserPassword(c.Request.Context(), username, password); err == nil {
				return user, nil
			} else if errors.Is(err, core.ErrCredentialsInvalid) {
				return core.User{}, errors.New(http.StatusUnauthorized, errCodeCredentialsInvalid, "Invalid Credentials")
			} else {
				return core.User{}, err
			}
		}
	} else if token, ok := checkAuthHeader(header, "bearer"); ok {
		if user, err := a.ReadAccessToken(c.Request.Context(), token); err == nil {
			return user, nil
		} else if errors.Is(err, core.ErrTokenExpired) || errors.Is(err, core.ErrTokenInvalid) {
			return core.User{}, errors.New(http.StatusUnauthorized, errCodeCredentialsInvalid, "Invalid Credentials")
		} else {
			return core.User{}, err
		}
	}
	return core.User{}, errors.New(http.StatusUnauthorized, errCodeAuthRequred, "Authorization scheme not recognized")
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
