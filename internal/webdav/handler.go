package webdav

import (
	"context"
	"strings"

	webdav "github.com/emersion/go-webdav"
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/vfs"
	"github.com/sirupsen/logrus"
)

type handler struct {
	vfsManager vfs.VfsManager
	prefix     string
}

func NewHandler(vfsManager vfs.VfsManager, prefix string) *handler {
	logrus.Info("Setting up WebDAV access at " + prefix)
	return &handler{
		vfsManager: vfsManager,
		prefix:     prefix,
	}
}

func (h *handler) HandleRequest(c *gin.Context) {
	path := c.Params.ByName("path")
	vfsName := strings.TrimLeft(path, "/")
	if vfsName == "" {
		// No path specified
		c.Writer.WriteHeader(404)
		return
	}
	index := strings.Index(vfsName, "/")
	if index != -1 {
		vfsName = vfsName[0:index]
	}
	vfs, err := h.vfsManager.GetVfs(context.Background(), vfsName)
	if err != nil {
		c.Writer.WriteHeader(404)
		return
	}

	webdavHandler := webdav.Handler{
		FileSystem: adapter{
			fs:     vfs,
			prefix: h.prefix + "/" + vfsName,
		},
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
