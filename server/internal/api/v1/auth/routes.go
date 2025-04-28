package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/user"
)

type loginResponse struct {
	AccessToken string               `json:"access_token"`
	User        loggedInUserResponse `json:"user"`
}
type loggedInUserResponse struct {
	Username string    `json:"username"`
	Display  string    `json:"display"`
	Home     uuid.UUID `json:"home"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/auth")
	group.POST("/password", handlePasswordAuth)
	group.POST("/set-cookie", authenticator.RequireToken, handleSetCookie)
}

func handlePasswordAuth(c *gin.Context) {
	email, ok := c.GetQuery("email")
	if !ok {
		panic(errors.NewError(http.StatusBadRequest, "missing_email", "Email Not Specified"))
	}
	password, ok := c.GetQuery("password")
	if !ok {
		panic(errors.NewError(http.StatusBadRequest, "missing_password", "Password Not Specified"))
	}

	userManager := user.ManagerFromContext(c.Request.Context())
	if user, err := userManager.VerifyUserPassword(email, password); err != nil {
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
	c.SetCookie("auth_token", token, 3600, "", c.Request.URL.Hostname(), secure, true)
}
