package webdav

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"

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

func (a adapter) ResourceByPath(ctx context.Context, name string) (core.Resource, error) {
	return a.fs.ResourceByPath(name)
}

func (a adapter) OpenRead(r core.Resource, start, len int64) (io.ReadCloser, error) {
	return a.fs.OpenRead(r, start, len)
}

func (a adapter) ReadDir(r core.Resource) ([]core.Resource, error) {
	return a.fs.ReadDir(r)
}

func (a adapter) OpenWrite(ctx context.Context, name string) (io.WriteCloser, error) {
	resource, err := a.ResourceByPath(ctx, name)

	if err != nil {
		if err == core.ErrResourceNotFound {
			// Try to create the resource if the parent collection exists
			name = strings.TrimRight(name, "/")
			index := strings.LastIndex(name, "/")
			parentPath := name[0:index]
			parent, err := a.ResourceByPath(ctx, parentPath)
			if err != nil {
				return nil, err
			}
			resourceName := name[index+1:]
			resourceId := uuid.New()
			resource, err = a.fs.CreateMemberResource(parent, resourceId, resourceName, false)
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

func (a adapter) RemoveAll(ctx context.Context, name string) error {
	resource, err := a.ResourceByPath(ctx, name)
	if err != nil {
		return err
	}
	_, err = a.fs.DeleteRecursive(resource, false)
	return err
}

func (a adapter) Mkdir(ctx context.Context, name string) error {
	if _, err := a.ResourceByPath(ctx, name); !errors.Is(err, core.ErrResourceNotFound) {
		if err == nil {
			return core.ErrResourceNameConflict
		}
		return err
	}
	name = strings.TrimRight(name, "/")
	index := strings.LastIndex(name, "/")
	parentPath := name[0:index]
	parent, err := a.ResourceByPath(ctx, parentPath)
	if err != nil {
		if errors.Is(err, core.ErrResourceNotFound) {
			return core.ErrParentNotFound
		}
		return err
	}
	dirName := name[index+1:]
	_, err = a.fs.CreateMemberResource(parent, uuid.New(), dirName, true)
	return err
}

func (a adapter) Move(ctx context.Context, src core.Resource, target string, overwrite bool) (core.Resource, error) {
	return a.fs.Move(src, target, overwrite)
}
func (a adapter) Copy(ctx context.Context, src core.Resource, target string, recursive, overwrite bool) (core.Resource, error) {
	return a.fs.Copy(src, target, uuid.New(), recursive, overwrite)
}
