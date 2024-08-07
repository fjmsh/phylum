package auth

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core"
)

const keyFileSystem = "filesystem"

func GetFileSystem(c *gin.Context) core.FileSystem {
	val, ok := c.Get(keyFileSystem)
	if !ok {
		return nil
	}
	return val.(core.FileSystem)
}
