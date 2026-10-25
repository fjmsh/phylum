package fs

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"github.com/gin-gonic/gin"
)

func handleInfoRequest(c *gin.Context) {
	path := fixPath(c.Param("path"))

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPath(path)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.FullResourceFromFS(fs, r, false))
}
