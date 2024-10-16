package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/routes/fs"
	"github.com/shroff/phylum/server/internal/core"
)

type myHomeResponse struct {
	User userResponse          `json:"user"`
	Home fs.ResourceLsResponse `json:"home"`
}

type mySharedResponse struct {
	Shared []core.Resource `json:"shared"`
}

func SetupMyRoutes(r *gin.RouterGroup, a *core.App) {
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
		User: responseFromUser(user),
		Home: fs.LsResponseFromResource(f, r),
	})
}

func createMySharedRouteHandler(a *core.App) func(*gin.Context) {
	return func(c *gin.Context) {
		user := auth.GetUser(c)
		shared, err := a.GetSharedResources(c.Request.Context(), user)
		if err != nil {
			panic(err)
		}
		c.JSON(200, mySharedResponse{Shared: shared})
	}
}
