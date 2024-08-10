package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core"
)

type userResponse struct {
	Email       string    `json:"email"`
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
		Email:       user.Email(),
		DisplayName: user.DisplayName(),
		Home:        user.Home(),
	}
}
