package my

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type homeResponse struct {
	User responses.LoggedInUser `json:"user"`
	Home responses.ResourceFull `json:"home"`
}

type sharedResponse struct {
	Shared []responses.Resource `json:"shared"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/my")
	group.GET("/shared", handleSharedRoute)
	group.GET("/bootstrap", handleBootstrapRoute)
	group.POST("/details", handleDetailsUpdateRoute)
	setupBookmarksRoutes(group)
}

func handleSharedRoute(c *gin.Context) {
	auth := authenticator.GetAuth(c)
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
