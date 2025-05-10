package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/user"
)

type passwordParams struct {
	Username string `json:"username" form:"username" binding:"required"`
	Password string `json:"password" form:"password" binding:"required"`
}

type loginResponse struct {
	AccessToken string               `json:"access_token"`
	User        loggedInUserResponse `json:"user"`
}
type loggedInUserResponse struct {
	Username string      `json:"username"`
	Display  string      `json:"display"`
	Home     pgtype.UUID `json:"home"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/auth")
	group.POST("/password", handlePasswordAuth)
	group.POST("/set-cookie", authenticator.RequireToken, handleSetCookie)
}

func handlePasswordAuth(c *gin.Context) {
	var params passwordParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(errors.NewError(http.StatusBadRequest, "missing_params", "Username or password not specified"))
	}

	userManager := user.ManagerFromContext(c.Request.Context())
	if user, err := userManager.VerifyUserPassword(params.Username, params.Password); err != nil {
		panic(err)
	} else {
		if token, err := userManager.CreateAccessToken(user.Username); err != nil {
			panic(err)
		} else {
			c.JSON(200, loginResponse{
				AccessToken: token,
				User: loggedInUserResponse{
					Username: user.Username,
					Display:  user.DisplayName,
					Home:     user.Home,
				},
			})
		}
	}
}

func handleSetCookie(c *gin.Context) {
	token := authenticator.GetToken(c)
	if token == "" {
		panic(errors.NewError(http.StatusBadRequest, "missing_token", "Auth Token Not Specified"))
	}
	secure := c.Request.URL.Scheme == "https"
	c.SetSameSite(http.SameSiteStrictMode)
	c.SetCookie("auth_token", token, 3600, "", c.Request.URL.Hostname(), secure, true)
}
