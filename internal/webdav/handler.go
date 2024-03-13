package webdav

import (
	"context"
	"strings"

	webdav "github.com/emersion/go-webdav"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/library"
	"github.com/sirupsen/logrus"
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
		FileSystem: adapter{
			lib:    library,
			prefix: h.prefix + "/" + idStr,
		},
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
