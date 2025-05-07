package webdav

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	webdav "github.com/shroff/phylum/server/internal/api/webdav/impl"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/sirupsen/logrus"
)

type handler struct {
	prefix     string
	lockSystem webdav.LockSystem
}

func SetupHandler(r *gin.RouterGroup) {
	logrus.Debug("Setting up WebDAV access at " + r.BasePath())
	handler := &handler{
		prefix:     r.BasePath(),
		lockSystem: webdav.NewMemLS(),
	}
	r.Any("/:user/*path", handler.HandleRequest)
}

func (h *handler) HandleRequest(c *gin.Context) {
	authSuccess := false
	var f fs.FileSystem
	if username, pass, ok := c.Request.BasicAuth(); ok {
		ctx := c.Request.Context()
		userManager := user.ManagerFromContext(ctx)
		if u, err := userManager.VerifyUserPassword(username, pass); err == nil {
			authSuccess = true
			if u.Username == c.Param("user") {
				f = u.OpenHomeFileSystem(ctx)
			} else {
				id, err := userManager.UserHome(c.Param("user"))
				if err != nil {
					panic(err)
				}
				f = u.OpenFileSystem(ctx, id)
			}
		} else if !errors.Is(err, user.ErrCredentialsInvalid) {
			panic(err)
		}
	}
	if !authSuccess {
		c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
		c.AbortWithStatus(http.StatusUnauthorized)
		return
	}

	webdavHandler := webdav.Handler{
		Prefix:     h.prefix,
		FileSystem: f,
		LockSystem: h.lockSystem,
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
