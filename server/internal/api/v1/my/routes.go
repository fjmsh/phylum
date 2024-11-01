package my

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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

type bookmarksResponse struct {
	Bookmarks []fs.ResourceInfo `json:"bookmarks"`
}
type bookmarkIDParams struct {
	ID uuid.UUID `json:"id" binding:"required"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/my")
	group.GET("/home", handleHomeRoute)
	group.GET("/shared", handleSharedRoute)
	group.GET("/bookmarks/list", handleBookmarksGetRoute)
	group.POST("/bookmarks/add", handleBookmarksAddRoute)
	group.POST("/bookmarks/remove", handleBookmarksRemoveRoute)
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

func handleBookmarksGetRoute(c *gin.Context) {
	u := auth.GetUser(c)
	bookmarks, err := user.CreateManager(c.Request.Context()).Bookmarks(u)
	if err != nil {
		panic(err)
	}
	c.JSON(200, bookmarksResponse{Bookmarks: bookmarks})
}

func handleBookmarksAddRoute(c *gin.Context) {
	var params bookmarkIDParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.ID == uuid.Nil {
		panic(errInvalidParams)
	}

	u := auth.GetUser(c)
	r, err := auth.GetFileSystem(c).ResourceByID(params.ID)
	if err != nil {
		panic(err)
	}
	err = user.CreateManager(c.Request.Context()).AddBookmark(u, r)
	if err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}

func handleBookmarksRemoveRoute(c *gin.Context) {
	var params bookmarkIDParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.ID == uuid.Nil {
		panic(errInvalidParams)
	}

	u := auth.GetUser(c)
	err = user.CreateManager(c.Request.Context()).RemoveBookmark(u, params.ID)
	if err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}
