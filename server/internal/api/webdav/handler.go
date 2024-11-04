package webdav

import (
	"net/http"

	"github.com/gin-gonic/gin"
	webdav "github.com/shroff/phylum/server/internal/api/webdav/impl"
	"github.com/shroff/phylum/server/internal/core/fs"
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
	val, ok := c.Get(keyFileSystem)
	if !ok {
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
	f := val.(fs.FileSystem)

	webdavHandler := webdav.Handler{
		Prefix:     h.prefix,
		FileSystem: f,
		LockSystem: h.lockSystem,
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
