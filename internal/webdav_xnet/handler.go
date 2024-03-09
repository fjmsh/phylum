package webdav

import (
	"context"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/library"
	"github.com/sirupsen/logrus"
	"golang.org/x/net/webdav"
)

type handler struct {
	libraryManager library.Manager
	prefix         string
}

func NewHandler(libraryManager library.Manager, prefix string) *handler {
	logrus.Info("Setting up WebDAV access at " + prefix)
	return &handler{
		libraryManager: libraryManager,
		prefix:         prefix,
	}
}

func (h *handler) HandleRequest(c *gin.Context) {
	path := c.Params.ByName("path")
	libraryName := strings.TrimLeft(path, "/")
	if libraryName == "" {
		// No path specified
		c.Writer.WriteHeader(404)
		return
	}
	index := strings.Index(libraryName, "/")
	if index != -1 {
		libraryName = libraryName[0:index]
	}
	library, err := h.libraryManager.Get(context.Background(), libraryName)
	if err != nil {
		c.Writer.WriteHeader(404)
		return
	}

	webdavHandler := webdav.Handler{
		Prefix:     h.prefix + "/" + libraryName,
		FileSystem: adapter{lib: library},
		LockSystem: webdav.NewMemLS(),
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
