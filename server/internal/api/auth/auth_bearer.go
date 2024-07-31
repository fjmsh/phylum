package auth

import (
	"errors"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/sirupsen/logrus"
)

func CreateBearerAuthHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(401, gin.H{
				"ERR_CODE": "auth_required",
			})
			return
		}
		authParts := strings.Split(authHeader, " ")
		if len(authParts) != 2 {
			c.AbortWithStatusJSON(401, gin.H{
				"ERR_CODE": "auth_malformed",
			})
			return
		}
		if authParts[0] != "bearer" {
			c.AbortWithStatusJSON(401, gin.H{
				"ERR_CODE": "auth_scheme_not_recognized",
			})
			return
		}

		username, err := a.VerifyAccessToken(authParts[1])
		if err != nil {
			if errors.Is(err, app.ErrAccessTokenExpired) || errors.Is(err, app.ErrAccessTokenInvalid) {
				c.AbortWithStatusJSON(401, gin.H{
					"ERR_CODE": "access_token_invalid",
				})
			} else {
				logrus.Warn(err.Error())
				c.AbortWithStatusJSON(500, gin.H{
					"ERR_CODE":    "unknown_error",
					"ERR_DETAILS": err.Error(),
				})
			}
			return
		}
		c.Set(keyUsername, username)
	}
}
