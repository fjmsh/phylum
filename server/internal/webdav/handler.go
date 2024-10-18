package webdav

import (
	"errors"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core"
	webdav "github.com/shroff/phylum/server/internal/webdav/impl"
	"github.com/sirupsen/logrus"
)

type handler struct {
	app        *core.App
	prefix     string
	lockSystem webdav.LockSystem
}

func SetupHandler(r *gin.RouterGroup, app *core.App) {
	logrus.Debug("Setting up WebDAV access at " + r.BasePath())
	handler := &handler{
		app:        app,
		prefix:     r.BasePath(),
		lockSystem: webdav.NewMemLS(),
	}
	r.Use(auth.CreateBasicAuthHandler(app))
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
}

func (h *handler) HandleRequest(c *gin.Context) {
	fs := auth.GetFileSystem(c)
	if fs == nil {
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
	webdavHandler := webdav.Handler{
		Prefix:     h.prefix,
		FileSystem: adapter{FileSystem: fs},
		LockSystem: h.lockSystem,
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}

type adapter struct {
	core.FileSystem
}

func (a adapter) OpenWriteTouch(name string) (io.WriteCloser, error) {
	resource, err := a.ResourceByPath(name)

	if errors.Is(err, core.ErrResourceNotFound) {
		resource, err = a.CreateResourceByPath(name, false)
		if err != nil {
			return nil, err
		}
	} else if err != nil {
		return nil, err
	} else if resource.Dir {
		return nil, core.ErrResourceCollection
	}

	return a.OpenWrite(resource)
}
