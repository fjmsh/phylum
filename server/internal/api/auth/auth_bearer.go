package auth

import (
	"errors"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/app"
)

const keyUsername = "username"

func CreateBearerAuthHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		authHeader := strings.Split(c.GetHeader("Authorization"), " ")
		if len(authHeader) != 2 {
			c.AbortWithStatusJSON(401, gin.H{
				"ERR_CODE": "authorization_malformed",
			})
			return
		}
		if authHeader[0] != "bearer" {
			c.AbortWithStatusJSON(401, gin.H{
				"ERR_CODE": "authorization_malformed",
			})
			return
		}

		username, err := a.VerifyAccessToken(authHeader[1])
		if err != nil {
			if errors.Is(err, app.ErrAccessTokenExpired) || errors.Is(err, app.ErrAccessTokenInvalid) {
				c.AbortWithStatusJSON(401, gin.H{
					"ERR_CODE": "access_token_invalid",
				})
			} else {
				c.AbortWithStatusJSON(401, gin.H{
					"ERR_CODE":    "unknown_error",
					"ERR_DETAILS": err.Error(),
				})
			}
			return
		}
		c.Set(keyUsername, username)
	}
}
