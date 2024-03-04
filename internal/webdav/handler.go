package webdav

import (
	"context"
	"strings"

	webdav "github.com/emersion/go-webdav"
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/phylumfs"
	"github.com/sirupsen/logrus"
)

type handler struct {
	backend phylumfs.Backend
	prefix  string
}

func NewHandler(backend phylumfs.Backend, prefix string) *handler {
	logrus.Info("Setting up WebDAV access at " + prefix)
	return &handler{
		backend: backend,
		prefix:  prefix,
	}
}

func (h *handler) HandleRequest(c *gin.Context) {
	path := c.Params.ByName("path")
	path = strings.TrimLeft(path, "/")
	if path == "" {
		// No path specified
		c.Writer.WriteHeader(404)
		return
	}
	index := strings.Index(path, "/")
	if index != -1 {
		path = path[0:index]
	}
	root, err := h.backend.FindRoot(context.Background(), path)
	if err != nil {
		c.Writer.WriteHeader(404)
		return
	}

	webdavHandler := webdav.Handler{
		FileSystem: adapter{
			fs:     root,
			prefix: h.prefix,
		},
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
