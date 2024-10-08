package routes

import (
	iofs "io/fs"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/api/routes/fs"
	"github.com/shroff/phylum/server/internal/core"
)

type myHomeResponse struct {
	User userResponse              `json:"user"`
	Home fs.ResourceDetailResponse `json:"home"`
}

type mySharedResponse struct {
	Shared []fs.ResourceMetadata `json:"shared"`
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
		if errors.Is(err, iofs.ErrNotExist) {
			err = errResourceNotFound
		}
		panic(err)
	}

	c.JSON(200, myHomeResponse{
		User: responseFromUser(user),
		Home: fs.DetailedResponseFromResource(f, r),
	})
}

func createMySharedRouteHandler(a *core.App) func(*gin.Context) {
	return func(c *gin.Context) {
		user := auth.GetUser(c)
		shared, err := a.GetSharedResources(c.Request.Context(), user)
		if err != nil {
			panic(err)
		}

		result := make([]fs.ResourceMetadata, len(shared))
		for i, r := range shared {
			result[i] = fs.ResponseFromResource(r)
		}
		c.JSON(200, mySharedResponse{Shared: result})
	}
}
