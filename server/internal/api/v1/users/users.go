package users

import (
	"context"
	"net/http"
	"strconv"

	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

var errInvalidParams = core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

func SetupUserRoutes(r *gin.RouterGroup) {
	group := r.Group("/users")
	group.GET("/list", handleUsersListRoute)
	group.POST("/invite", handleInviteRequest)
}

func handleUsersListRoute(c *gin.Context) {
	var since int64
	if s := c.Request.URL.Query().Get("since"); s != "" {
		var err error
		since, err = strconv.ParseInt(s, 10, 64)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	users, err := ListUsers(c.Request.Context(), since)
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{
		"users": users,
	})
}

func ListUsers(ctx context.Context, since int64) ([]responses.User, error) {
	var users []responses.User
	if res, err := core.ListUsers(db.Get(ctx), since); err != nil {
		return users, err
	} else {
		users = make([]responses.User, len(res))
		for i, u := range res {
			users[i] = responses.User{
				ID:    u.ID,
				Email: u.Email,
				Name:  u.Name,
			}
		}
		return users, nil
	}
}
