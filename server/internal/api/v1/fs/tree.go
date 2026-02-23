package fs

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"github.com/gin-gonic/gin"
)

func handleTreeRequest(c *gin.Context) {
	// Trim leading '/'
	path := c.Param("path")[1:]

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPathWithRoot(path)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.FullResourceFromFS(fs, r, true))
}
