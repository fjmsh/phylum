package my

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/api/v1/users"
	"github.com/shroff/phylum/server/internal/core"
)

func handleBootstrapRoute(c *gin.Context) {
	var since int64
	if s := c.Request.URL.Query().Get("since"); s != "" {
		var err error
		since, err = strconv.ParseInt(s, 10, 64)
		if err != nil {
			panic(core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Parameters"))
		}
	}

	if response, err := Bootstrap(c.Request.Context(), authenticator.GetUser(c), since); err != nil {
		panic(err)
	} else {
		c.JSON(200, response)
	}
}

func Bootstrap(ctx context.Context, u core.User, since int64) (responses.Bootstrap, error) {
	if bookmarks, err := ListBookmarks(ctx, u, since); err != nil {
		return responses.Bootstrap{}, err
	} else if users, err := users.ListUsers(ctx, since); err != nil {
		return responses.Bootstrap{}, err
	} else {
		return responses.Bootstrap{
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
			Clear:     since == 0,
		}, nil
	}

}
