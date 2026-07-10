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

func handleTokenLogin(c *gin.Context) {
	var params struct {
		Token string `json:"token" form:"token" binding:"required"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "login token not specified"))
	}

	loginAndSendResponse(c, func(db db.TxHandler) (*auth.Auth, string, error) {
		return auth.Get().PerformTokenLogin(db, params.Token)
	})
}

func handleTokenRequest(c *gin.Context) {
	var params struct {
		Email string `json:"email" form:"email" binding:"required"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if user, token, err := auth.Get().CreateLoginToken(db, params.Email); err != nil {
			// Do not indicate that there was an error if no user was found
			if !errors.Is(err, core.ErrUserNotFound) {
				return err
			}
		} else {
			// TODO: #jobs #mail #error
			go func() {
				mail.SendTokenLoginEmail(user, token)
			}()
		}
		return nil
	}); err != nil {
		panic(err)
	} else {
		c.JSON(http.StatusOK, gin.H{})
	}
}
