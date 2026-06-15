package users

import (
	"context"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type user struct {
	ID          int32    `json:"id"`
	Email       string   `json:"email"`
	Name        string   `json:"name"`
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

	users, err := ListUsers(c.Request.Context(), auth.UserPermissions().HasPermission(core.UserPermissionFilesRead))
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{
		"users": users,
	})
}

func ListUsers(ctx context.Context, includeHome bool) ([]user, error) {
	var users []user
	if res, err := core.ListUsers(db.Get(ctx), 0); err != nil {
		return users, err
	} else {
		users = make([]user, len(res))
		for i, u := range res {
			users[i] = user{
				ID:          u.ID,
				Email:       u.Email,
				Name:        u.Name,
				Permissions: u.Permissions,
			}
			if includeHome && u.Home.Valid {
				users[i].Home = u.Home.String()
			}
		}
		return users, nil
	}
}
