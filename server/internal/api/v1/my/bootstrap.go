package my

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/user"
)

type bootstrapResponse struct {
	User      responses.LoggedInUser `json:"user"`
	Bookmarks []Bookmark             `json:"bookmarks"`
	Users     []responses.User       `json:"users"`
	Until     int                    `json:"until"`
}

func handleBootstrapRoute(c *gin.Context) {
	var since int
	if sinceStr := c.Request.URL.Query().Get("since"); sinceStr != "" {
		var err error
		since, err = strconv.Atoi(sinceStr)
		if err != nil {
			panic(errors.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Parameters"))
		}
	}

	u := authenticator.GetUser(c)
	var bookmarks []Bookmark
	var users []responses.User

	if res, err := user.ManagerFromContext(c.Request.Context()).ListBookmarks(u, int64(since)); err != nil {
		panic(err)
	} else {
		bookmarks = make([]Bookmark, len(res))
		for i, b := range res {
			bookmarks[i] = Bookmark{
				ResourceID: b.ResourceID,
				Name:       b.Name,
				Dir:        b.Dir,
				Created:    b.Created.UnixMilli(),
			}
		}
	}

	if res, err := user.ManagerFromContext(c.Request.Context()).ListUsers(int64(since)); err != nil {
		panic(err)
	} else {
		users = make([]responses.User, len(res))
		for i, u := range res {
			users[i] = responses.User{
				ID:    u.ID,
				Email: u.Email,
				Name:  u.Name,
			}
		}
	}

	response := bootstrapResponse{
		User: responses.LoggedInUser{
			User: responses.User{
				ID:    u.ID,
				Email: u.Email,
				Name:  u.Name,
			},
			Home:        u.Home,
			Permissions: u.Permissions,
		},
		Bookmarks: bookmarks,
		Users:     users,
		Until:     int(time.Now().UnixMilli()) - 100,
	}
	c.JSON(200, response)
}
