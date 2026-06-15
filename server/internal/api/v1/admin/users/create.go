package users

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type createUserParams struct {
	Email        string `json:"email" form:"email" binding:"required"`
	Name         string `json:"name" form:"name"`
	Password     string `json:"password" form:"password"`
	NoCreateHome bool   `json:"no_create_home" form:"no_create_home"`
}

func handleCreateRequest(c *gin.Context) {
	var params createUserParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	a := authenticator.GetAuth(c)
	if !a.HasScope("admin:users:create") {
		panic(core.ErrInsufficientScope)
	}
	if !a.UserPermissions().HasPermission(core.UserPermissionUsersCreate) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to create users"))
	}

	var user core.User
	err = db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if user, err = core.CreateUser(db, params.Email, params.Name, false); err != nil {
			return err
		}
		if auth.PasswordAuthEnabled() {
			if params.Password != "" {
				if err := auth.UpdateUserPassword(db, params.Email, params.Password); err != nil {
					return err
				}
			}
		} else if params.Password != "" {
			panic(core.NewError(http.StatusBadRequest, "password_auth_disabled", "Attempting to set password when password auth is disabled"))
		}
		return nil
	})
	if err != nil {
		panic(err)
	}
	c.JSON(200, responses.User{ID: user.ID, Email: user.Email, Name: user.Name})
}
