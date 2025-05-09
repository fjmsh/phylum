package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
)

func handleInfoRequest(c *gin.Context) {
	path := c.Param("path")

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPathWithMaybeRoot(path)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.FullResourceFromFS(r))
}
