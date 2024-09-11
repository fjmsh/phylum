package auth

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
)

const errCodeAuthRequred = "auth_required"
const errCodeTokenInvalid = "token_invalid"

func CreateBearerAuthHandler(a *core.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			panic(errors.New(401, errCodeAuthRequred, "Authorization Header Required"))
		}
		authParts := strings.Split(authHeader, " ")
		if len(authParts) != 2 {
			panic(errors.New(401, errCodeAuthRequred, "Authorization Header Malformed"))
		}
		if authParts[0] != "bearer" {
			panic(errors.New(401, errCodeAuthRequred, "Authorization Type Not Recognized"))
		}

		user, err := a.ReadAccessToken(ctx, authParts[1])
		if err != nil {
			if errors.Is(err, core.ErrTokenExpired) || errors.Is(err, core.ErrTokenInvalid) {
				panic(errors.New(401, errCodeTokenInvalid, "Authorization Token Invalid"))
			}
			panic(err)
		}
		if fs, err := a.OpenFileSystem(ctx, user); err != nil {
			logrus.Warn(err)
			c.AbortWithStatus(http.StatusInternalServerError)
		} else {
			c.Set(keyUser, user)
			c.Set(keyFileSystem, fs)
		}
	}
}
