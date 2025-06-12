package my

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type bookmarksResponse struct {
	Bookmarks []responses.Bookmark `json:"bookmarks"`
	Until     int64                `json:"until"`
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
	var since int64
	if s := c.Request.URL.Query().Get("since"); s != "" {
		var err error
		since, err = strconv.ParseInt(s, 10, 64)
		if err != nil {
			panic(core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Parameters"))
		}
	}

	u := authenticator.GetUser(c)
	if bookmarks, err := ListBookmarks(c.Request.Context(), u, since); err != nil {
		panic(err)
	} else {
		c.JSON(200, bookmarksResponse{
			Bookmarks: bookmarks,
			Until:     time.Now().UnixMilli() - 100,
		})
	}
}

func handleBookmarksAddRoute(c *gin.Context) {
	var params bookmarkAddParams
	c.ShouldBind(&params)

	u := authenticator.GetUser(c)
	r, err := authenticator.GetFileSystem(c).ResourceByPathWithRoot(params.Path)
	if err != nil {
		panic(err)
	}
	var b core.Bookmark
	err = db.Get(c.Request.Context()).RunInTx(func(db db.TxHandler) error {
		b, err = core.AddBookmark(db, u, r, params.Name)
		return err
	})
	if err != nil {
		panic(err)
	}
	c.JSON(200,
		responses.Bookmark{
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
	if err := db.Get(c.Request.Context()).RunInTx(func(db db.TxHandler) error {
		return core.RemoveBookmark(db, u, params.ID)
	}); err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}

func ListBookmarks(ctx context.Context, u core.User, since int64) ([]responses.Bookmark, error) {
	var bookmarks []responses.Bookmark
	if res, err := core.ListBookmarks(db.Get(ctx), u, since); err != nil {
		return bookmarks, err
	} else {
		bookmarks = make([]responses.Bookmark, len(res))
		for i, b := range res {
			bookmarks[i] = responses.Bookmark{
				ResourceID: b.ResourceID,
				Name:       b.Name,
				Dir:        b.Dir,
				Created:    b.Created.UnixMilli(),
			}
		}
		return bookmarks, nil
	}
}
