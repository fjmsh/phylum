package auth

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/shroff/phylum/server/internal/cryptutil"
)

func CreateBasicAuthHandler(app *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		username, pass, ok := c.Request.BasicAuth()
		if !ok {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}
		user, err := app.FindUser(context.Background(), username)
		if err != nil {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}
		ok, err = cryptutil.VerifyPassword(pass, user.PasswordHash)
		if err != nil {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}
		if !ok {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}
		c.Set(keyUsername, user)
	}
}
