package webdav

import (
	"context"
	"errors"
	"io"
	"io/fs"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/user"
	"github.com/shroff/phylum/server/internal/webdav"
	"github.com/sirupsen/logrus"
)

type handler struct {
	fs     *core.FileSystem
	prefix string
}

func SetupHandler(r *gin.RouterGroup, fs *core.FileSystem, userManager *user.Manager) {
	logrus.Info("Setting up WebDAV access at " + r.BasePath())
	handler := &handler{
		fs:     fs,
		prefix: r.BasePath(),
	}
	r.Use(func(c *gin.Context) {
		username, pass, ok := c.Request.BasicAuth()
		if !ok {
			c.Header("WWW-Authenticate", "Basic realm=\"Authorization Required\"")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}
		user, err := userManager.FindUser(context.Background(), username)
		if err != nil {
			c.Header("WWW-Authenticate", "Basic realm=\"Incorrect Username or Password\"")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}
		ok, err = cryptutil.VerifyPassword(pass, user.PasswordHash)
		if err != nil {
			c.Header("WWW-Authenticate", "Basic realm=\"Incorrect Username or Password\"")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}
		if !ok {
			c.Header("WWW-Authenticate", "Basic realm=\"Incorrect Username or Password\"")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}
		c.Set("user", user)
		c.Next()
	})
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
	// path := c.Params.ByName("path")
	// idStr := strings.TrimLeft(path, "/")
	// if idStr == "" {
	// 	// No path specified
	// 	c.Writer.WriteHeader(404)
	// 	return
	// }
	// index := strings.Index(idStr, "/")
	// if index != -1 {
	// 	idStr = idStr[0:index]
	// }
	// id, err := uuid.Parse(idStr)
	// if err != nil {
	// 	c.Writer.WriteHeader(404)
	// 	return
	// }

	// library, err := h.libraryManager.Get(context.Background(), id)
	// if err != nil {
	// 	c.Writer.WriteHeader(404)
	// 	return
	// }

	webdavHandler := webdav.Handler{
		Prefix:     h.prefix,
		FileSystem: h,
		LockSystem: webdav.NewMemLS(),
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}

func (a handler) Stat(ctx context.Context, name string) (core.File, error) {
	return a.fs.ResourceByPath(ctx, name)
}

func (a handler) OpenWrite(ctx context.Context, name string) (io.WriteCloser, error) {
	resource, err := a.fs.ResourceByPath(ctx, name)
	resourceId := resource.ID()

	if err != nil {
		if err == fs.ErrNotExist {
			// Try to create the resource if the parent collection exists
			name = strings.TrimRight(name, "/")
			index := strings.LastIndex(name, "/")
			parentPath := name[0:index]
			parent, err := a.fs.ResourceByPath(ctx, parentPath)
			if err != nil {
				return nil, fs.ErrNotExist
			}
			resourceName := name[index+1:]
			resourceId = uuid.New()
			err = a.fs.CreateResource(ctx, resourceId, parent.ID(), resourceName, false)
			if err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
	} else if resource.IsDir() {
		return nil, errors.New("cannot open collection for write")
	}
	return a.fs.OpenWrite(ctx, resourceId)
}

func (a handler) RemoveAll(ctx context.Context, name string) error {
	resource, err := a.fs.ResourceByPath(ctx, name)
	if err != nil {
		return fs.ErrNotExist
	}
	return a.fs.DeleteRecursive(ctx, resource.ID())
}

func (a handler) Mkdir(ctx context.Context, name string) error {
	if _, err := a.fs.ResourceByPath(ctx, name); err == nil {
		return fs.ErrExist
	}
	name = strings.TrimRight(name, "/")
	index := strings.LastIndex(name, "/")
	parentPath := name[0:index]
	parent, err := a.fs.ResourceByPath(ctx, parentPath)
	if err != nil {
		return fs.ErrNotExist
	}
	dirName := name[index+1:]
	err = a.fs.CreateResource(ctx, uuid.New(), parent.ID(), dirName, true)
	return err
}

func (a handler) Rename(ctx context.Context, oldName, newName string) error {
	src, err := a.fs.ResourceByPath(ctx, oldName)
	if err != nil {
		return fs.ErrNotExist
	}

	_, err = a.fs.ResourceByPath(ctx, newName)
	if err == nil {
		return fs.ErrExist
	}

	newName = strings.TrimRight(newName, "/")
	index := strings.LastIndex(newName, "/")
	parentPath := newName[0:index]
	parent, err := a.fs.ResourceByPath(ctx, parentPath)
	newName = newName[index+1:]

	if err != nil {
		return fs.ErrNotExist
	}

	if err = a.fs.Move(ctx, src.ID(), parent.ID(), newName); err != nil {
		return err
	}
	return nil
}
