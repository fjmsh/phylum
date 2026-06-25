package users

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

func handlePasswordUpdateRequest(c *gin.Context) {
	var params struct {
		Email       string `json:"email" form:"email" binding:"required"`
		NewPassword string `json:"new_password" form:"new_password" binding:"required"`
	}
	err := c.Bind(&params)
	if err != nil {
		panic(err)
	}
	a := authenticator.GetAuth(c)
	if !a.HasScope("admin:" + core.UserPermissionUsersAuthPasswordUpdate) {
		panic(core.ErrInsufficientScope)
	}
	if !a.UserPermissions().HasPermission(core.UserPermissionUsersAuthPasswordUpdate) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to update user passwords"))
	}

	err = db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if err := auth.UpdateUserPassword(db, params.Email, params.NewPassword); err != nil {
			if e, ok := err.(*auth.PasswordRequirementsError); ok {
				return core.NewError(http.StatusBadRequest, "new_password_invalid", e.Error())
			}
			panic(err)
		}
		return nil
	})
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{})
}
