package webdav

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/user"
)

const keyFileSystem = "filesystem"

func createBasicAuthHandler() func(c *gin.Context) {
	return func(c *gin.Context) {
		authSuccess := false
		if username, pass, ok := c.Request.BasicAuth(); ok {
			ctx := c.Request.Context()
			if u, err := user.CreateManager(ctx).VerifyUserPassword(username, pass); err == nil {
				c.Set(keyFileSystem, u.OpenFileSystem(ctx))
				authSuccess = true
			} else if !errors.Is(err, user.ErrCredentialsInvalid) {
				panic(err)
			}
		}
		if !authSuccess {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			c.AbortWithStatus(http.StatusUnauthorized)
		}
	}
}
