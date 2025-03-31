package my

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/v1/fs"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/user"
)

var errInvalidParams = errors.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

type homeResponse struct {
	User user.User       `json:"user"`
	Home fs.FullResponse `json:"home"`
}

type sharedResponse struct {
	Shared []fs.InfoResponse `json:"shared"`
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
		Home: fs.CreateFullResponse(r),
	})
}

func handleSharedRoute(c *gin.Context) {
	f := auth.GetFileSystem(c)
	shared, err := f.SharedResources()
	if err != nil {
		panic(err)
	}
	res := make([]fs.InfoResponse, len(shared))
	for i, r := range shared {
		res[i] = fs.CreateResponse(r)
	}
	c.JSON(200, sharedResponse{Shared: res})
}
