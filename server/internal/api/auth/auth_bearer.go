package auth

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/sirupsen/logrus"
)

const errCodeAuthRequred = "auth_required"
const errCodeTokenInvalid = "token_invalid"

func CreateBearerAuthHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
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

		userID, err := a.VerifyAccessToken(authParts[1])
		if err != nil {
			if errors.Is(err, app.ErrTokenExpired) || errors.Is(err, app.ErrTokenInvalid) {
				panic(errors.Err{Status: 401, Code: errCodeTokenInvalid})
			}
			panic(err)
		}
		if fs, err := a.OpenFileSystem(c.Request.Context(), userID); err != nil {
			logrus.Warn(err)
			c.AbortWithStatus(http.StatusInternalServerError)
		} else {
			c.Set(keyFileSystem, fs)
		}
	}
}
