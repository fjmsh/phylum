package users

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type user struct {
	responses.User
	Permissions []string `json:"permissions"`
	Home        string   `json:"home,omitempty"`
}

func handleListRequest(c *gin.Context) {
	auth := authenticator.GetAuth(c)
	if !auth.HasScope("admin:users:list") {
		panic(core.ErrInsufficientScope)
	}
	if !auth.UserPermissions().HasPermission(core.UserPermissionUsersList) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to list users"))
	}

	includeHome := auth.UserPermissions().HasPermission(core.UserPermissionFilesRead)

	if res, err := core.ListUsers(db.Get(c.Request.Context()), 0); err != nil {
		panic(err)
	} else {
		users := make([]user, len(res))
		for i, u := range res {
			users[i] = user{
				User: responses.User{
					ID:    u.ID,
					Email: u.Email,
					Name:  u.Name,
				},
				Permissions: u.Permissions,
			}
			if includeHome && u.Home.Valid {
				users[i].Home = u.Home.String()
			}
		}
		c.JSON(200, gin.H{
			"users": users,
		})
	}
}
