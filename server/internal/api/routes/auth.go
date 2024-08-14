package routes

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/core"
)

type loginResponse struct {
	AccessToken string       `json:"access_token"`
	User        userResponse `json:"user"`
}

func SetupAuthRoutes(r *gin.RouterGroup, a *core.App) {
	group := r.Group("/auth")
	group.POST("/login", createLoginRouteHandler(a))
}

func createLoginRouteHandler(a *core.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		email, ok := c.GetQuery("email")
		if !ok {
			panic(errors.New(http.StatusBadRequest, "missing_email", "Email Not Specified"))
		}
		password, ok := c.GetQuery("password")
		if !ok {
			panic(errors.New(http.StatusBadRequest, "missing_password", "Password Not Specified"))
		}

		if user, err := a.VerifyUserPassword(c.Request.Context(), email, password); err != nil {
			if errors.Is(err, core.ErrCredentialsInvalid) {
				panic(errors.New(http.StatusUnauthorized, "credentials_invalid", "Invalid Credentials"))
			}
			panic(err)
		} else {
			if token, err := a.CreateAccessToken(c.Request.Context(), user.ID); err != nil {
				panic(err)
			} else {
				c.JSON(200, loginResponse{
					AccessToken: token,
					User:        responseFromUser(user),
				})
			}
		}
	}
}
