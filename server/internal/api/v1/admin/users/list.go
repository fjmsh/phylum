package users

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

func handleListRequest(c *gin.Context) {
	auth := authenticator.GetAuth(c)

	includeHome := auth.UserPrivileges().HasPermission(core.UserPrivilegeFilesRead)

	if res, err := core.ListUsers(db.Get(c.Request.Context()), 0); err != nil {
		panic(err)
	} else {
		users := make([]responses.FullUser, len(res))
		for i, u := range res {
			users[i] = responses.FullUser{
				User: responses.User{
					ID:    u.ID,
					Email: u.Email,
					Name:  u.Name,
				},
				Permissions: u.Permissions,
			}
			if includeHome && u.Home.Valid {
				users[i].Home = u.Home
			}
		}
		c.JSON(200, gin.H{
			"users": users,
		})
	}
}
