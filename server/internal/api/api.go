package api

import (
	"errors"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/sirupsen/logrus"
)

func Setup(r *gin.RouterGroup) {
	setupAuthRoutes(r)
	r.Use(func(c *gin.Context) {
		authHeader := strings.Split(c.GetHeader("Authorization"), " ")
		logrus.Info(authHeader)
		rersponseObj := gin.H{
			"ERR": "Unauthorized",
		}
		c.JSON(401, rersponseObj)
	})
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
		if errors.Is(err, app.ErrInvalidUsernamePassword) {
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
			"expires":      token.Expires.Time.String(),
		})
	}
}
