package api

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/app"
)

func setupAuthRoutes(r *gin.RouterGroup, a *app.App) {
	group := r.Group("/auth")
	group.POST("/login", createLoginRouteHandler(a))
}

func createLoginRouteHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		username, ok := c.GetQuery("username")
		if !ok {
			c.AbortWithStatusJSON(401, gin.H{
				"ERR_CODE":    "missing_params",
				"ERR_DETAILS": "Missing username input",
			})
			return
		}
		password, ok := c.GetQuery("password")
		if !ok {
			c.AbortWithStatusJSON(401, gin.H{
				"ERR_CODE":    "missing_params",
				"ERR_DETAILS": "Missing password input",
			})
			return
		}

		if token, err := a.CreateAccessToken(username, password); err != nil {
			if errors.Is(err, app.ErrCredentialsInvalid) {
				c.AbortWithStatusJSON(401, gin.H{
					"ERR_CODE": "invalid_username_or_password",
				})
			} else {
				c.AbortWithStatusJSON(401, gin.H{
					"ERR_DETAILS": err.Error(),
				})
			}
		} else {
			c.JSON(200, gin.H{
				"access_token": token.ID,
				"expires":      token.Expires,
			})
		}
	}
}
