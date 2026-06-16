package users

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type grantParams struct {
	Email       string   `json:"user_email" form:"email"`
	ID          int32    `json:"user_id" form:"user_id"`
	Permissions []string `json:"permissions" form:"permissions" binding:"required"`
}

func handlePermissionsRequest(c *gin.Context) {
	var params grantParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}
	if (params.Email == "" && params.ID <= 0) || (params.Email != "" && params.ID > 0) {
		panic(errInvalidParams)
	}

	auth := authenticator.GetAuth(c)
	if !auth.HasScope("admin:users:permissions") {
		panic(core.ErrInsufficientScope)
	}
	if !auth.UserPermissions().HasPermission(core.UserPermissionUsersPermissions) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to update user permissions"))
	}

	var u core.User
	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if params.ID <= 0 {
			if u, err = core.UserByEmail(db, params.Email); err != nil {
				return err
			}
		} else {
			if u, err = core.UserByID(db, params.ID); err != nil {
				return err
			}
		}

		grant := make(map[core.UserPermission]bool)
		revoke := make(map[core.UserPermission]bool)
		for _, p := range params.Permissions {
			grant[p] = true
		}
		for _, p := range u.Permissions {
			if _, ok := grant[p]; ok {
				delete(grant, p)
			} else {
				revoke[p] = true
			}
		}
		for p := range grant {
			if !auth.UserPermissions().HasPermission(p) {
				core.NewError(http.StatusBadRequest, "insufficient_permissions", "Cannot grant permission "+p)
			}
		}

		for p := range revoke {
			if !auth.UserPermissions().HasPermission(p) {
				core.NewError(http.StatusBadRequest, "insufficient_permissions", "Cannot revoke permission "+p)
			}
		}

		core.SetUserPermissions(db, params.ID, params.Permissions)
		return nil
	}); err != nil {
		panic(err)
	}

	home := ""
	if auth.UserPermissions().HasPermission(core.UserPermissionFilesRead) {
		home = u.Home.String()
	}
	c.JSON(200, user{
		User: responses.User{
			ID:    u.ID,
			Email: u.Email,
			Name:  u.Name,
		},
		Permissions: params.Permissions,
		Home:        home,
	})
}
