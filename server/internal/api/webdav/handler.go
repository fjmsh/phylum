package webdav

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	webdav "github.com/shroff/phylum/server/internal/api/webdav/impl"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/sirupsen/logrus"
)

type handler struct {
	prefix     string
	lockSystem webdav.LockSystem
}

func createBasicAuthHandler() func(c *gin.Context) {
	return func(c *gin.Context) {
		authSuccess := false
		if username, pass, ok := c.Request.BasicAuth(); ok {
			ctx := c.Request.Context()
			if u, err := user.CreateManager(ctx).VerifyUserPassword(username, pass); err == nil {
				auth.Set(c, u, u.OpenFileSystem(ctx))
				authSuccess = true
			} else if !errors.Is(err, user.ErrCredentialsInvalid) {
				panic(err)
			}
		}
		if !authSuccess {
			c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
			panic(auth.ErrRequired)
		}
	}
}

func SetupHandler(r *gin.RouterGroup) {
	logrus.Debug("Setting up WebDAV access at " + r.BasePath())
	handler := &handler{
		prefix:     r.BasePath(),
		lockSystem: webdav.NewMemLS(),
	}
	r.Use(createBasicAuthHandler())
	r.Handle("OPTIONS", "*path", handler.HandleRequest)
	r.Handle("GET", "*path", handler.HandleRequest)
	r.Handle("PUT", "*path", handler.HandleRequest)
	r.Handle("HEAD", "*path", handler.HandleRequest)
	r.Handle("POST", "*path", handler.HandleRequest)
	r.Handle("DELETE", "*path", handler.HandleRequest)
	r.Handle("MOVE", "*path", handler.HandleRequest)
	r.Handle("COPY", "*path", handler.HandleRequest)
	r.Handle("MKCOL", "*path", handler.HandleRequest)
	r.Handle("PROPFIND", "*path", handler.HandleRequest)
	r.Handle("PROPPATCH", "*path", handler.HandleRequest)
	r.Handle("LOCK", "*path", handler.HandleRequest)
	r.Handle("UNLOCK", "*path", handler.HandleRequest)
}

func (h *handler) HandleRequest(c *gin.Context) {
	fs := auth.GetFileSystem(c)
	if fs == nil {
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
	webdavHandler := webdav.Handler{
		Prefix:     h.prefix,
		FileSystem: fs,
		LockSystem: h.lockSystem,
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
