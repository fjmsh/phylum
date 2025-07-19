package auth

import (
	"errors"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type passwordUpdateParams struct {
	Email       string `json:"email" form:"email"`
	OldPassword string `json:"old_password" form:"old_password"`
	NewPassword string `json:"new_password" form:"new_password"`
}

func handlePasswordChangeRoute(c *gin.Context) {
	var params passwordUpdateParams
	err := c.Bind(&params)
	if err != nil {
		panic(err)
	}

	if err := auth.VerifyAndChangeUserPassword(db.Get(c.Request.Context()), params.Email, params.OldPassword, params.NewPassword); err != nil {
		if errors.Is(err, auth.ErrCredentialsInvalid) {
			panic(core.NewError(http.StatusBadRequest, "password_incorrect", "current password is incorrect"))
		}
		if e, ok := err.(*auth.PasswordRequirementsError); ok {
			panic(core.NewError(http.StatusBadRequest, "new_password_invalid", e.Error()))
		}
		panic(err)
	}

	c.JSON(200, gin.H{})
}
