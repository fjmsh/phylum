package my

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	fsapi "github.com/shroff/phylum/server/internal/api/v1/fs"
	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
)

type myHomeResponse struct {
	User user.User                `json:"user"`
	Home fsapi.ResourceLsResponse `json:"home"`
}

type mySharedResponse struct {
	Shared []fs.Resource `json:"shared"`
}

func SetupRoutes(r *gin.RouterGroup, a *app.App) {
	group := r.Group("/my")
	group.GET("/home", handleMyHomeRoute)
	group.GET("/shared", createMySharedRouteHandler(a))
}

func handleMyHomeRoute(c *gin.Context) {
	user := auth.GetUser(c)
	f := auth.GetFileSystem(c)
	r, err := f.ResourceByID(user.Home)
	if err != nil {
		panic(err)
	}

	c.JSON(200, myHomeResponse{
		User: user,
		Home: fsapi.LsResponseFromResource(f, r),
	})
}

func createMySharedRouteHandler(a *app.App) func(*gin.Context) {
	return func(c *gin.Context) {
		user := auth.GetUser(c)
		shared, err := a.OpenUserManager(c.Request.Context()).GetSharedResources(user)
		if err != nil {
			panic(err)
		}
		c.JSON(200, mySharedResponse{Shared: shared})
	}
}
