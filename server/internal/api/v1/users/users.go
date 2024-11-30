package users

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/user"
)

func SetupUserRoutes(r *gin.RouterGroup) {
	group := r.Group("/users")
	group.GET("/list", handleUsersListRoute)
}

func handleUsersListRoute(c *gin.Context) {
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
	users, err := user.CreateManager(c.Request.Context()).ListUsers(since)
	if err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{
		"users": users,
	})
}
