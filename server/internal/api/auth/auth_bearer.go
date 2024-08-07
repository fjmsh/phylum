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
			panic(errors.Err{Status: 401, Code: errCodeAuthRequred})
		}
		authParts := strings.Split(authHeader, " ")
		if len(authParts) != 2 {
			panic(errors.Err{Status: 401, Code: errCodeAuthRequred})
		}
		if authParts[0] != "bearer" {
			panic(errors.Err{Status: 401, Code: errCodeAuthRequred})
		}

		userID, err := a.VerifyAccessToken(ctx, authParts[1])
		if err != nil {
			if errors.Is(err, core.ErrTokenExpired) || errors.Is(err, core.ErrTokenInvalid) {
				panic(errors.Err{Status: 401, Code: errCodeTokenInvalid})
			}
			panic(err)
		}
		if fs, err := a.OpenFileSystem(ctx, userID); err != nil {
			logrus.Warn(err)
			c.AbortWithStatus(http.StatusInternalServerError)
		} else {
			c.Set(keyFileSystem, fs)
		}
	}
}
