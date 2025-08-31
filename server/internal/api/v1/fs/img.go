package fs

import (
	"io"
	"net/http"
	"strconv"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/img"
	"github.com/gin-gonic/gin"
)

func handleImgRequest(c *gin.Context) {
	// Trim leading '/'
	path := c.Param("path")[1:]
	versionIDStr := c.Query("version")
	resolutionStr := c.Query("res")
	resolution, err := strconv.Atoi(resolutionStr)
	if err != nil {
		panic(errInvalidParams)
	}

	f := authenticator.GetFileSystem(c)
	r, err := f.ResourceByPathWithRoot(path)
	if err != nil {
		panic(err)
	}

	if img, err := f.GetImg(r, versionIDStr, img.Res(resolution)); err != nil {
		panic(err)
	} else if img == nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		// TODO: Caching
		c.Writer.WriteHeader(http.StatusOK)
		c.Writer.Header().Set("Content-Type", "image/webp")
		defer img.Close()
		io.Copy(c.Writer, img)
	}
}
