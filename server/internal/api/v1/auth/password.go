package auth

import (
	"errors"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
)

type passwordUpdateParams struct {
	Email       string `json:"email" form:"email"`
	OldPassword string `json:"old_password" form:"old_password"`
	NewPassword string `json:"new_password" form:"new_password"`
}

func handlePasswordLogin(c *gin.Context) {
	var params struct {
		Email    string `json:"email" form:"email" binding:"required"`
		Password string `json:"password" form:"password" binding:"required"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Email or password not specified"))
	}

	loginAndSendResponse(c, func(db db.TxHandler) (*auth.Auth, string, error) {
		return auth.Get().PerformPasswordLogin(db, params.Email, params.Password)
	})
}

func handlePasswordChange(c *gin.Context) {
	var params passwordUpdateParams
	err := c.Bind(&params)
	if err != nil {
		panic(err)
	}

	if err := auth.Get().VerifyAndChangeUserPassword(db.Get(c.Request.Context()), params.Email, params.OldPassword, params.NewPassword); err != nil {
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

func handlePasswordRequestReset(c *gin.Context) {
	var params struct {
		Email string `json:"email" form:"email" binding:"required"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if user, token, err := auth.Get().CreateResetToken(db, params.Email); err != nil {
			// Do not indicate that there was an error if no user was found
			if !errors.Is(err, core.ErrUserNotFound) {
				return err
			}
		} else {
			// TODO: #jobs #mail #error
			go func() {
				mail.SendPasswordResetEmail(user, token)
			}()
		}
		return nil
	}); err != nil {
		panic(err)
	} else {
		c.JSON(http.StatusOK, gin.H{})
	}
}

func handlePasswordReset(c *gin.Context) {
	var params struct {
		Email    string `json:"email" form:"email" binding:"required"`
		Token    string `json:"token" form:"token" binding:"required"`
		Password string `json:"password" form:"password" binding:"required"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	loginAndSendResponse(c, func(db db.TxHandler) (*auth.Auth, string, error) {
		return auth.Get().ResetUserPassword(db, params.Email, params.Token, params.Password)
	})
}
