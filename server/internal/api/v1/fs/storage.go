package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
)

type DiskUsageResponse struct {
	TotalSize int64 `json:"size"`
	Files     int64 `json:"files"`
	Dirs      int64 `json:"dirs"`
}

func handleDiskUsageRequest(c *gin.Context) {
	path := c.Query("path")

	fs := authenticator.GetFileSystem(c)
	resource, err := fs.ResourceByRootedPath(path)
	if err != nil {
		panic(err)
	}

	info, err := resource.DiskUsage()
	if err != nil {
		panic(err)
	}
	c.JSON(200, DiskUsageResponse{
		TotalSize: info.TotalSize,
		Files:     info.Files,
		Dirs:      info.Dirs,
	})
}
