package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core"
)

type userResponse struct {
	UserID      int32     `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"name"`
	Home        uuid.UUID `json:"home"`
}

func SetupUserRoutes(r *gin.RouterGroup) {
	group := r.Group("/users")
	group.GET("/me", handleUserMeRoute)
}

func handleUserMeRoute(c *gin.Context) {
	c.JSON(200, responseFromUser(auth.GetUser(c)))
}

func responseFromUser(user core.User) userResponse {
	return userResponse{
		UserID:      user.ID(),
		Username:    user.Username(),
		DisplayName: user.DisplayName(),
		Home:        user.Home(),
	}
}
