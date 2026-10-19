package user

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type sharedResponse struct {
	Shared []responses.Resource `json:"shared"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/user")
	group.GET("/bootstrap", handleBootstrapRoute)
	group.GET("/shared", handleSharedRoute)
	group.POST("/profile", handleProfileUpdateRoute)
	setupBookmarksRoutes(group)
	setupKeysRoutes(group)
}

func handleSharedRoute(c *gin.Context) {
	auth := authenticator.GetAuth(c)
	if !auth.HasScope("user:shared:list") {
		panic(core.ErrInsufficientPermissions)
	}
	shared, err := core.SharedResources(db.Get(c.Request.Context()), auth.UserID())
	if err != nil {
		panic(err)
	}
	res := make([]responses.Resource, len(shared))
	for i, r := range shared {
		res[i] = responses.ResourceFromFS(r)
	}
	c.JSON(200, sharedResponse{Shared: res})
}
