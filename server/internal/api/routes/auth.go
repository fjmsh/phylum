package routes

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/core"
)

func SetupAuthRoutes(r *gin.RouterGroup, a *core.App) {
	group := r.Group("/auth")
	group.POST("/login", createLoginRouteHandler(a))
}

func createLoginRouteHandler(a *core.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		username, ok := c.GetQuery("username")
		if !ok {
			panic(errors.New(http.StatusBadRequest, "missing_username", ""))
		}
		password, ok := c.GetQuery("password")
		if !ok {
			panic(errors.New(http.StatusBadRequest, "missing_password", ""))
		}

		if token, err := a.CreateAccessToken(c.Request.Context(), username, password); err != nil {
			if errors.Is(err, core.ErrCredentialsInvalid) {
				panic(errors.New(http.StatusUnauthorized, "credentials_invalid", ""))
			}
			panic(err)
		} else {
			c.JSON(200, gin.H{
				"access_token": token.ID,
				"expires":      token.Expires,
			})
		}
	}
}
