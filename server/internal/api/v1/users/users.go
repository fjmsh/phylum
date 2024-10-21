package users

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
)

func SetupUserRoutes(r *gin.RouterGroup) {
	group := r.Group("/users")
	group.GET("/me", handleUserMeRoute)
}

func handleUserMeRoute(c *gin.Context) {
	c.JSON(200, auth.GetUser(c))
}
