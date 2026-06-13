package users

import "github.com/gin-gonic/gin"

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/users")
	group.GET("/list", handleUsersListRoute)
}
