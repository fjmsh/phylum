package webdav

import (
	"context"
	"errors"
	"io"
	"io/fs"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/shroff/phylum/server/internal/app/core"
	"github.com/shroff/phylum/server/internal/webdav"
	"github.com/sirupsen/logrus"
)

type handler struct {
	app    *app.App
	prefix string
}

func SetupHandler(r *gin.RouterGroup, app *app.App) {
	logrus.Info("Setting up WebDAV access at " + r.BasePath())
	handler := &handler{
		app:    app,
		prefix: r.BasePath(),
	}
	r.Use(auth.CreateBasicAuthHandler(app))
	r.Handle("OPTIONS", "/*path", handler.HandleRequest)
	r.Handle("GET", "/*path", handler.HandleRequest)
	r.Handle("PUT", "/*path", handler.HandleRequest)
	r.Handle("HEAD", "/*path", handler.HandleRequest)
	r.Handle("POST", "/*path", handler.HandleRequest)
	r.Handle("DELETE", "/*path", handler.HandleRequest)
	r.Handle("MOVE", "/*path", handler.HandleRequest)
	r.Handle("COPY", "/*path", handler.HandleRequest)
	r.Handle("MKCOL", "/*path", handler.HandleRequest)
	r.Handle("PROPFIND", "/*path", handler.HandleRequest)
	r.Handle("PROPPATCH", "/*path", handler.HandleRequest)
}

func (h *handler) HandleRequest(c *gin.Context) {
	path := c.Params.ByName("path")
	identifier := strings.TrimLeft(path, "/")
	if identifier == "" {
		// No path specified
		c.JSON(404, gin.H{
			"ERR_CODE": "err_silo_path_not_specified",
		})
		return
	}
	index := strings.Index(identifier, "/")
	if index != -1 {
		identifier = identifier[0:index]
	}
	silo, err := h.app.FindSilo(context.Background(), identifier)
	if err != nil {
		c.Writer.WriteHeader(404)
		c.JSON(404, gin.H{
			"ERR_CODE":    "err_silo_not_found",
			"ERR_DETAILS": err.Error(),
		})
		return
	}

	userID := auth.GetUserID(c)

	webdavHandler := webdav.Handler{
		Prefix:     h.prefix + "/" + identifier,
		FileSystem: adapter{silo: silo, userID: userID},
		LockSystem: webdav.NewMemLS(),
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}

type adapter struct {
	silo   core.Silo
	userID int32
}

func (a adapter) Stat(ctx context.Context, name string) (core.Resource, error) {
	return a.silo.ResourceByPath(ctx, name, a.userID)
}

func (a adapter) OpenWrite(ctx context.Context, name string) (io.WriteCloser, error) {
	resource, err := a.Stat(ctx, name)

	if err != nil {
		if err == fs.ErrNotExist {
			// Try to create the resource if the parent collection exists
			name = strings.TrimRight(name, "/")
			index := strings.LastIndex(name, "/")
			parentPath := name[0:index]
			parent, err := a.Stat(ctx, parentPath)
			if err != nil {
				return nil, fs.ErrNotExist
			}
			resourceName := name[index+1:]
			resourceId := uuid.New()
			resource, err = parent.CreateMemberResource(ctx, resourceId, resourceName, false)
			if err != nil {
				return nil, err
			}
			return resource.OpenWrite(ctx)
		}
		return nil, err
	}
	if resource.IsDir() {
		return nil, errors.New("cannot open collection for write")
	}
	return resource.OpenWrite(ctx)
}

func (a adapter) RemoveAll(ctx context.Context, name string) error {
	resource, err := a.Stat(ctx, name)
	if err != nil {
		return fs.ErrNotExist
	}
	return resource.DeleteRecursive(ctx, false)
}

func (a adapter) Mkdir(ctx context.Context, name string) error {
	if _, err := a.Stat(ctx, name); err == nil {
		return fs.ErrExist
	}
	name = strings.TrimRight(name, "/")
	index := strings.LastIndex(name, "/")
	parentPath := name[0:index]
	parent, err := a.Stat(ctx, parentPath)
	if err != nil {
		return fs.ErrNotExist
	}
	dirName := name[index+1:]
	_, err = parent.CreateMemberResource(ctx, uuid.New(), dirName, true)
	return err
}

func (a adapter) Rename(ctx context.Context, oldName, newName string) error {
	src, err := a.Stat(ctx, oldName)
	if err != nil {
		return fs.ErrNotExist
	}

	_, err = a.Stat(ctx, newName)
	if err == nil {
		return fs.ErrExist
	}

	newName = strings.TrimRight(newName, "/")
	index := strings.LastIndex(newName, "/")
	parentPath := newName[0:index]
	parent, err := a.Stat(ctx, parentPath)
	newName = newName[index+1:]

	if err != nil {
		return fs.ErrNotExist
	}

	if err = a.silo.Move(ctx, src.ID(), parent.ID(), newName); err != nil {
		return err
	}
	return nil
}
