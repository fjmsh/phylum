package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/sirupsen/logrus"
)

func CreateBasicAuthHandler(app *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		var userID int32
		if username, pass, ok := c.Request.BasicAuth(); ok {
			if res, err := app.VerifyUserPassword(c.Request.Context(), username, pass); err == nil {
				userID = res
			}
		}
		if userID == 0 {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			c.AbortWithStatus(http.StatusUnauthorized)
		} else if fs, err := app.OpenFileSystem(c.Request.Context(), userID); err != nil {
			logrus.Warn(err)
			c.AbortWithStatus(http.StatusInternalServerError)
		} else {
			c.Set(keyUserID, userID)
			c.Set(keyFileSystem, fs)
		}
	}
}
