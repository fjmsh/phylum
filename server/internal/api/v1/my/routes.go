package my

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
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
	group.GET("/home", handleHomeRoute)
	group.GET("/shared", handleSharedRoute)
	setupBookmarksRoutes(group)
}

func handleHomeRoute(c *gin.Context) {
	user := authenticator.GetUser(c)
	f := authenticator.GetFileSystem(c)
	r, err := f.ResourceByPathWithRoot("")
	if err != nil {
		panic(err)
	}

	c.JSON(200, homeResponse{
		User: responses.LoggedInUser{
			User: responses.User{
				ID:          user.ID,
				Email:       user.Email,
				DisplayName: user.DisplayName,
			},
			Home:        user.Home,
			Permissions: user.Permissions,
		},
		Home: responses.FullResourceFromFS(r),
	})
}

func handleSharedRoute(c *gin.Context) {
	f := authenticator.GetFileSystem(c)
	u := authenticator.GetUser(c)
	shared, err := f.SharedResources(u.Home)
	if err != nil {
		panic(err)
	}
	res := make([]responses.Resource, len(shared))
	for i, r := range shared {
		res[i] = responses.ResourceFromFS(r)
	}
	c.JSON(200, sharedResponse{Shared: res})
}
