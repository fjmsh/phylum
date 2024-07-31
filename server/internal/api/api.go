package api

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/app"
)

func Setup(r *gin.RouterGroup, app *app.App) {
	setupAuthRoutes(r)
	r.Use(auth.CreateBearerAuthHandler(app))
	setupResourceRoutes(r)
}

func setupAuthRoutes(r *gin.RouterGroup) {
	group := r.Group("/auth")
	group.POST("/login", handleLoginRoute)
}

func setupResourceRoutes(r *gin.RouterGroup) {
	group := r.Group("/resources")
	group.GET("/:id/metadata")
	group.PUT("/:id/metadata")
	group.GET("/:id/contents")
	group.PUT("/:id/contents")
}

func handleLoginRoute(c *gin.Context) {
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

	if token, err := app.Default.CreateAccessToken(username, password); err != nil {
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
