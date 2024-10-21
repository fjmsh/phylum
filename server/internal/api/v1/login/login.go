package login

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/user"
)

type loginResponse struct {
	AccessToken string    `json:"access_token"`
	User        user.User `json:"user"`
}

func SetupRoutes(r *gin.RouterGroup, a app.App) {
	group := r.Group("/login")
	group.POST("/password", createLoginRouteHandler(a))
}

func createLoginRouteHandler(a app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		email, ok := c.GetQuery("email")
		if !ok {
			panic(errors.NewError(http.StatusBadRequest, "missing_email", "Email Not Specified"))
		}
		password, ok := c.GetQuery("password")
		if !ok {
			panic(errors.NewError(http.StatusBadRequest, "missing_password", "Password Not Specified"))
		}

		userManager := user.CreateManager(c.Request.Context())
		if user, err := userManager.VerifyUserPassword(email, password); err != nil {
			panic(err)
		} else {
			if token, err := userManager.CreateAccessToken(user.Username); err != nil {
				panic(err)
			} else {
				c.JSON(200, loginResponse{
					AccessToken: token,
					User:        user,
				})
			}
		}
	}
}
