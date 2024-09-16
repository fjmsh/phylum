package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/core"
)

func CreateBasicAuthHandler(a *core.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		authSuccess := false
		if username, pass, ok := c.Request.BasicAuth(); ok {
			if user, err := a.VerifyUserPassword(c.Request.Context(), username, pass); err == nil {
				c.Set(keyUser, user)
				c.Set(keyFileSystem, a.OpenFileSystem(c.Request.Context(), user))
				authSuccess = true
			} else if !errors.Is(err, core.ErrCredentialsInvalid) {
				panic(err)
			}
		}
		if !authSuccess {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			panic(errors.New(http.StatusUnauthorized, errCodeAuthRequred, "Authorization Required"))
		}
	}
}
