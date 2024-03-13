package webdav

import (
	"context"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/library"
	"github.com/shroff/phylum/server/internal/user"
	"github.com/sirupsen/logrus"
	"golang.org/x/net/webdav"
)

type handler struct {
	libraryManager library.Manager
	prefix         string
}

func SetupHandler(r *gin.RouterGroup, libraryManager library.Manager, userManager user.Manager) {
	logrus.Info("Setting up WebDAV access at " + r.BasePath())
	handler := &handler{
		libraryManager: libraryManager,
		prefix:         r.BasePath(),
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
	path := c.Params.ByName("path")
	idStr := strings.TrimLeft(path, "/")
	if idStr == "" {
		// No path specified
		c.Writer.WriteHeader(404)
		return
	}
	index := strings.Index(idStr, "/")
	if index != -1 {
		idStr = idStr[0:index]
	}
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.Writer.WriteHeader(404)
		return
	}

	library, err := h.libraryManager.Get(context.Background(), id)
	if err != nil {
		c.Writer.WriteHeader(404)
		return
	}

	webdavHandler := webdav.Handler{
		Prefix:     h.prefix + "/" + idStr,
		FileSystem: adapter{lib: library},
		LockSystem: webdav.NewMemLS(),
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
