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
	User user.User                `json:"user"`
	Home fsapi.ResourceLsResponse `json:"home"`
}

type sharedResponse struct {
	Shared []fs.Resource `json:"shared"`
}

type bookmarksResponse struct {
	Bookmarks []fs.Resource `json:"bookmarks"`
}
type addBookmarkParams struct {
	ID uuid.UUID `json:"id" binding:"required"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/my")
	group.GET("/home", handleHomeRoute)
	group.GET("/shared", handleSharedRoute)
	group.GET("/bookmarks/list", handleBookmarksGetRoute)
	group.POST("/bookmarks/add", handleBookmarksAddRoute)
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
		Home: fsapi.LsResponseFromResource(f, r),
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
	var params addBookmarkParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.ID == uuid.Nil {
		panic(errInvalidParams)
	}

	u := auth.GetUser(c)
	err = user.CreateManager(c.Request.Context()).AddBookmark(u, params.ID)
	if err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}
