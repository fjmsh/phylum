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

func setupBookmarksRoutes(r *gin.RouterGroup) {
	group := r.Group("/bookmarks")
	group.POST("/add/:id", handleBookmarksAddRoute)
	group.POST("/remove/:id", handleBookmarksRemoveRoute)
	group.GET("/list", handleBookmarksGetRoute)
}

func handleBookmarksGetRoute(c *gin.Context) {
	u := authenticator.GetUser(c)
	res, err := user.ManagerFromContext(c.Request.Context()).ListBookmarks(u)
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

	u := authenticator.GetUser(c)
	r, err := authenticator.GetFileSystem(c).ResourceByID(id)
	if err != nil {
		panic(err)
	}
	b, err := user.ManagerFromContext(c.Request.Context()).AddBookmark(u, r, name)
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
	idStr, ok := c.Params.Get("id")
	if !ok {
		panic(errInvalidParams)
	}
	id := uuid.MustParse(idStr)

	u := authenticator.GetUser(c)
	if err := user.ManagerFromContext(c.Request.Context()).RemoveBookmark(u, id); err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}
