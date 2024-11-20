package my

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	fsapi "github.com/shroff/phylum/server/internal/api/v1/fs"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
)

var errInvalidParams = errors.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

type homeResponse struct {
	User user.User              `json:"user"`
	Home fsapi.ResourceResponse `json:"home"`
}

type sharedResponse struct {
	Shared []fs.ResourceInfo `json:"shared"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/my")
	group.GET("/home", handleHomeRoute)
	group.GET("/shared", handleSharedRoute)
	setupBookmarksRoutes(group)
}

func handleHomeRoute(c *gin.Context) {
	user := auth.GetUser(c)
	f := auth.GetFileSystem(c)
	r, err := f.ResourceByID(user.Home)
	if err != nil {
		panic(err)
	}

	c.JSON(200, homeResponse{
		User: user,
		Home: fsapi.LsResponseFromResource(r),
	})
}

func handleSharedRoute(c *gin.Context) {
	u := auth.GetUser(c)
	shared, err := user.CreateManager(c.Request.Context()).SharedResources(u)
	if err != nil {
		panic(err)
	}
	c.JSON(200, sharedResponse{Shared: shared})
}
