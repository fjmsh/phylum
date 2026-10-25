package fs

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"github.com/gin-gonic/gin"
)

type DiskUsageResponse struct {
	TotalSize int64 `json:"size"`
	Files     int64 `json:"files"`
	Dirs      int64 `json:"dirs"`
}

func handleDiskUsageRequest(c *gin.Context) {
	// Trim leading '/'
	path := fixPath(c.Param("path"))

	fs := authenticator.GetFileSystem(c)
	resource, err := fs.ResourceByPath(path)
	if err != nil {
		panic(err)
	}

	info, err := fs.DiskUsage(resource)
	if err != nil {
		panic(err)
	}
	c.JSON(200, DiskUsageResponse{
		TotalSize: info.TotalSize,
		Files:     info.Files,
		Dirs:      info.Dirs,
	})
}
