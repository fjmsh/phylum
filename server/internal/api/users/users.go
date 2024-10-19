package users

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core"
)

type UserResponse struct {
	Username    string    `json:"username"`
	DisplayName string    `json:"name"`
	Home        uuid.UUID `json:"home"`
}

func SetupUserRoutes(r *gin.RouterGroup) {
	group := r.Group("/users")
	group.GET("/me", handleUserMeRoute)
}

func handleUserMeRoute(c *gin.Context) {
	c.JSON(200, ResponseFromUser(auth.GetUser(c)))
}

func ResponseFromUser(user core.User) UserResponse {
	return UserResponse{
		Username:    user.Username,
		DisplayName: user.DisplayName,
		Home:        user.Home,
	}
}
