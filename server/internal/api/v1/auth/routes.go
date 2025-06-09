package auth

import (
	"errors"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/my"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
)

type passwordParams struct {
	Email    string `json:"email" form:"email" binding:"required"`
	Password string `json:"password" form:"password" binding:"required"`
}

type requestPasswordResetParams struct {
	Email string `json:"email" form:"email" binding:"required"`
}

type resetPasswordParams struct {
	Email    string `json:"email" form:"email" binding:"required"`
	Token    string `json:"token" form:"token" binding:"required"`
	Password string `json:"password" form:"password" binding:"required"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/auth")
	group.POST("/password", handlePasswordAuth)
	group.POST("/request-password-reset", handleRequestPasswordReset)
	group.POST("/reset-password", handleResetPassword)
	group.POST("/set-cookie", authenticator.RequireToken, handleSetCookie)
}

func handlePasswordAuth(c *gin.Context) {
	var params passwordParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Email or password not specified"))
	}

	if user, token, err := auth.CreateAccessToken(c.Request.Context(), params.Email, params.Password); err != nil {
		if errors.Is(err, auth.ErrCredentialsInvalid) {
			err = core.NewError(http.StatusBadRequest, "missing_params", "Username or password invalid")
		}
		panic(err)
	} else if bootstrap, err := my.Bootstrap(c.Request.Context(), user, 0); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.Login{
			AccessToken: token,
			Bootstrap:   bootstrap,
		})
	}

}

func handleRequestPasswordReset(c *gin.Context) {
	var params requestPasswordResetParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if user, token, err := auth.CreateResetToken(c.Request.Context(), params.Email); err != nil {
		// Do not indicate that there was an error if no user was found
		if errors.Is(err, core.ErrUserNotFound) {
			c.JSON(200, gin.H{})
			return
		}
		panic(err)
	} else {
		go func() {
			mail.SendPasswordResetEmail(user, token)
		}()
	}
	c.JSON(200, gin.H{})
}

func handleResetPassword(c *gin.Context) {
	var params resetPasswordParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if user, token, err := auth.ResetUserPassword(c.Request.Context(), params.Email, params.Token, params.Password); err != nil {
		panic(err)
	} else if bootstrap, err := my.Bootstrap(c.Request.Context(), user, 0); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.Login{
			AccessToken: token,
			Bootstrap:   bootstrap,
		})
	}
}

func handleSetCookie(c *gin.Context) {
	token := authenticator.GetToken(c)
	if token == "" {
		panic(core.NewError(http.StatusBadRequest, "missing_token", "Auth Token Not Specified"))
	}
	secure := c.Request.URL.Scheme == "https"
	c.SetSameSite(http.SameSiteStrictMode)
	c.SetCookie("auth_token", token, 3600, "", c.Request.URL.Hostname(), secure, true)
}
