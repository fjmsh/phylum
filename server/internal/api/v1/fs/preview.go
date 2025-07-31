package fs

import (
	"io"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"github.com/gin-gonic/gin"
)

func handlePreviewRequest(c *gin.Context) {
	// Trim leading '/'
	path := c.Param("path")[1:]
	versionIDStr := c.Query("version")

	f := authenticator.GetFileSystem(c)
	r, err := f.ResourceByPathWithRoot(path)
	if err != nil {
		panic(err)
	}

	if preview, err := f.GetPreview(r, versionIDStr); err != nil {
		panic(err)
	} else if preview == nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.Writer.WriteHeader(http.StatusOK)
		c.Writer.Header().Set("Content-Type", "image/webp")
		defer preview.Close()
		io.Copy(c.Writer, preview)
	}
}
