package webdav

import (
	"errors"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core"
	webdav "github.com/shroff/phylum/server/internal/webdav/impl"
	"github.com/sirupsen/logrus"
)

type handler struct {
	app    *core.App
	prefix string
}

func SetupHandler(r *gin.RouterGroup, app *core.App) {
	logrus.Debug("Setting up WebDAV access at " + r.BasePath())
	handler := &handler{
		app:    app,
		prefix: r.BasePath(),
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
		FileSystem: adapter{fs: fs},
		LockSystem: webdav.NewMemLS(),
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}

type adapter struct {
	fs core.FileSystem
}

func (a adapter) ResourceByPath(name string) (core.Resource, error) {
	return a.fs.ResourceByPath(name)
}

func (a adapter) OpenRead(r core.Resource, start, len int64) (io.ReadCloser, error) {
	return a.fs.OpenRead(r, start, len)
}

func (a adapter) ReadDir(r core.Resource) ([]core.Resource, error) {
	return a.fs.ReadDir(r)
}

func (a adapter) OpenWrite(name string) (io.WriteCloser, error) {
	resource, err := a.ResourceByPath(name)

	if err != nil {
		if errors.Is(err, core.ErrResourceNotFound) {
			resource, err = a.fs.CreateResourceByPath(name, false)
			if err != nil {
				return nil, err
			}
			return a.fs.OpenWrite(resource)
		}
		return nil, err
	}
	if resource.Dir {
		return nil, core.ErrResourceCollection
	}
	return a.fs.OpenWrite(resource)
}

func (a adapter) RemoveAll(r core.Resource) (uuid.UUIDs, error) {
	return a.fs.DeleteRecursive(r, false)
}

func (a adapter) Mkdir(name string) (core.Resource, error) {
	return a.fs.CreateResourceByPath(name, true)
}

func (a adapter) Move(src core.Resource, target string, overwrite bool) (core.Resource, error) {
	return a.fs.Move(src, target, overwrite)
}
func (a adapter) Copy(src core.Resource, target string, recursive, overwrite bool) (core.Resource, error) {
	return a.fs.Copy(src, target, uuid.New(), recursive, overwrite)
}
