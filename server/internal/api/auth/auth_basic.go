package auth

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/app"
)

func CreateBasicAuthHandler(app *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		username, pass, ok := c.Request.BasicAuth()
		if !ok {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			c.Status(http.StatusUnauthorized)
			return
		}
		if userID, err := app.VerifyUserPassword(context.Background(), username, pass); err != nil {

			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			c.Status(http.StatusUnauthorized)
			return
		} else {
			c.Set(keyUserID, userID)
		}
	}
}
