package auth

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
)

func CreateBasicAuthHandler(a *core.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		if username, pass, ok := c.Request.BasicAuth(); !ok {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			c.AbortWithStatus(http.StatusUnauthorized)
		} else if user, err := a.VerifyUserPassword(c.Request.Context(), username, pass); err != nil {
			if errors.Is(err, core.ErrCredentialsInvalid) {
				c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
				c.AbortWithStatus(http.StatusUnauthorized)
			} else {
				logrus.Warn(err)
				c.AbortWithStatus(http.StatusInternalServerError)
			}
		} else if fs, err := a.OpenFileSystem(c.Request.Context(), user); err != nil {
			logrus.Warn(err)
			c.AbortWithStatus(http.StatusInternalServerError)
		} else {
			c.Set(keyUser, user)
			c.Set(keyFileSystem, fs)
		}
	}
}
