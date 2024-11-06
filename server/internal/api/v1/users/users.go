package users

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/user"
)

func SetupUserRoutes(r *gin.RouterGroup) {
	group := r.Group("/users")
	group.GET("/list", handleUsersListRoute)
}

func handleUsersListRoute(c *gin.Context) {
	users, err := user.CreateManager(c.Request.Context()).AllUsers()
	if err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{
		"users": users,
	})
}
