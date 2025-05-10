package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
)

func handleInfoRequest(c *gin.Context) {
	// Trim leading '/'
	path := c.Param("path")[1:]

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPathWithRoot(path)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.FullResourceFromFS(r))
}
