package login

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/users"
	"github.com/shroff/phylum/server/internal/core"
)

type loginResponse struct {
	AccessToken string             `json:"access_token"`
	User        users.UserResponse `json:"user"`
}

func SetupRoutes(r *gin.RouterGroup, a *core.App) {
	group := r.Group("/login")
	group.POST("/password", createLoginRouteHandler(a))
}

func createLoginRouteHandler(a *core.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		email, ok := c.GetQuery("email")
		if !ok {
			panic(core.NewError(http.StatusBadRequest, "missing_email", "Email Not Specified"))
		}
		password, ok := c.GetQuery("password")
		if !ok {
			panic(core.NewError(http.StatusBadRequest, "missing_password", "Password Not Specified"))
		}

		if user, err := a.VerifyUserPassword(c.Request.Context(), email, password); err != nil {
			panic(err)
		} else {
			if token, err := a.CreateAccessToken(c.Request.Context(), user.Username); err != nil {
				panic(err)
			} else {
				c.JSON(200, loginResponse{
					AccessToken: token,
					User:        users.ResponseFromUser(user),
				})
			}
		}
	}
}
