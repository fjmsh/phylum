package my

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/core/user"
)

type bookmarksResponse struct {
	Bookmarks []Bookmark `json:"bookmarks"`
	Until     int64      `json:"until"`
}

type Bookmark struct {
	ResourceID uuid.UUID `json:"resource_id"`
	Name       string    `json:"name"`
	Dir        bool      `json:"dir"`
	Created    int64     `json:"created"`
}

type bookmarkAddParams struct {
	Path string `json:"path" form:"path" binding:"required"`
	Name string `json:"name" form:"name"`
}

type bookmarkRemoveParams struct {
	ID uuid.UUID `json:"id" form:"id" binding:"required"`
}

func setupBookmarksRoutes(r *gin.RouterGroup) {
	group := r.Group("/bookmarks")
	group.POST("/add", handleBookmarksAddRoute)
	group.POST("/remove", handleBookmarksRemoveRoute)
	group.GET("/list", handleBookmarksGetRoute)
}

func handleBookmarksGetRoute(c *gin.Context) {
	u := authenticator.GetUser(c)
	res, err := user.ManagerFromContext(c.Request.Context()).ListBookmarks(u, 0)
	if err != nil {
		panic(err)
	}
	bookmarks := make([]Bookmark, len(res))
	for i, b := range res {
		bookmarks[i] = Bookmark{
			ResourceID: b.ResourceID,
			Name:       b.Name,
			Dir:        b.Dir,
			Created:    b.Created.UnixMilli(),
		}
	}
	c.JSON(200, bookmarksResponse{
		Bookmarks: bookmarks,
		Until:     time.Now().UnixMilli() - 100,
	})
}

func handleBookmarksAddRoute(c *gin.Context) {
	var params bookmarkAddParams
	c.ShouldBind(&params)

	u := authenticator.GetUser(c)
	r, err := authenticator.GetFileSystem(c).ResourceByPathWithRoot(params.Path)
	if err != nil {
		panic(err)
	}
	b, err := user.ManagerFromContext(c.Request.Context()).AddBookmark(u, r, params.Name)
	if err != nil {
		panic(err)
	}
	c.JSON(200,
		Bookmark{
			ResourceID: b.ResourceID,
			Name:       b.Name,
			Dir:        b.Dir,
			Created:    b.Created.UnixMilli(),
		},
	)
}

func handleBookmarksRemoveRoute(c *gin.Context) {
	var params bookmarkRemoveParams
	c.ShouldBind(&params)

	u := authenticator.GetUser(c)
	if err := user.ManagerFromContext(c.Request.Context()).RemoveBookmark(u, params.ID); err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}
