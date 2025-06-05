package auth

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/my"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core"
	core1 "github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/mail"
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
		panic(core1.NewError(http.StatusBadRequest, "missing_params", "Email or password not specified"))
	}

	userManager := core.UserManagerFromContext(c.Request.Context())
	if user, err := userManager.VerifyUserPassword(params.Email, params.Password); err != nil {
		panic(err)
	} else if token, err := userManager.CreateAccessToken(user); err != nil {
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
		panic(core1.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	userManager := core.UserManagerFromContext(c.Request.Context())
	u, err := userManager.UserByEmail(params.Email)
	if errors.Is(err, core.ErrUserNotFound) {
		c.JSON(200, gin.H{})
		return
	}
	if err != nil {
		panic(err)
	}

	if token, err := userManager.CreateResetToken(u); err != nil {
		panic(err)
	} else {
		go func() {
			mail.SendPasswordResetEmail(u, token)
		}()
	}
	c.JSON(200, gin.H{})
}

func handleResetPassword(c *gin.Context) {
	var params resetPasswordParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core1.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	userManager := core.UserManagerFromContext(c.Request.Context())
	if user, err := userManager.UserByEmail(params.Email); err != nil {
		panic(err)
	} else if err := userManager.ResetUserPassword(user, params.Token, params.Password); err != nil {
		panic(err)
	} else if token, err := userManager.CreateAccessToken(user); err != nil {
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
		panic(core1.NewError(http.StatusBadRequest, "missing_token", "Auth Token Not Specified"))
	}
	secure := c.Request.URL.Scheme == "https"
	c.SetSameSite(http.SameSiteStrictMode)
	c.SetCookie("auth_token", token, 3600, "", c.Request.URL.Hostname(), secure, true)
}
