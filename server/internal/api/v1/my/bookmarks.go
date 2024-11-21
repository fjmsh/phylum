package my

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/user"
)

type bookmarksResponse struct {
	Bookmarks []user.Bookmark `json:"bookmarks"`
	Until     int64           `json:"until"`
}

func setupBookmarksRoutes(r *gin.RouterGroup) {
	group := r.Group("/bookmarks")
	group.POST("/add/:id", handleBookmarksAddRoute)
	group.POST("/remove/:id", handleBookmarksRemoveRoute)
	group.GET("/list", handleBookmarksGetRoute)
}

func handleBookmarksGetRoute(c *gin.Context) {
	var since *time.Time
	sinceStr := c.Query("since")
	if sinceStr != "" {
		sinceInt, err := strconv.ParseInt(sinceStr, 10, 64)
		if err != nil {
			panic(err)
		}
		t := time.UnixMilli(sinceInt - 1000).UTC()
		since = &t
	}
	u := auth.GetUser(c)
	bookmarks, err := user.CreateManager(c.Request.Context()).ListBookmarks(u, since)
	if err != nil {
		panic(err)
	}
	c.JSON(200, bookmarksResponse{
		Bookmarks: bookmarks,
		Until:     time.Now().UnixMilli(),
	})
}

func handleBookmarksAddRoute(c *gin.Context) {
	idStr, ok := c.Params.Get("id")
	name := c.Query("name")
	if !ok {
		panic(errInvalidParams)
	}
	id := uuid.MustParse(idStr)

	u := auth.GetUser(c)
	r, err := auth.GetFileSystem(c).ResourceByID(id)
	if err != nil {
		panic(err)
	}
	b, err := user.CreateManager(c.Request.Context()).AddBookmark(u, r, name)
	if err != nil {
		panic(err)
	}
	c.JSON(200, b)
}

func handleBookmarksRemoveRoute(c *gin.Context) {
	idStr, ok := c.Params.Get("id")
	if !ok {
		panic(errInvalidParams)
	}
	id := uuid.MustParse(idStr)

	u := auth.GetUser(c)
	b, err := user.CreateManager(c.Request.Context()).RemoveBookmark(u, id)
	if err != nil {
		panic(err)
	}
	c.JSON(200, b)
}
