package auth

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core"
)

const keyUser = "user"
const keyFileSystem = "filesystem"

func GetUser(c *gin.Context) core.User {
	val, ok := c.Get(keyUser)
	if !ok {
		return nil
	}
	return val.(core.User)
}

func GetFileSystem(c *gin.Context) core.FileSystem {
	val, ok := c.Get(keyFileSystem)
	if !ok {
		return nil
	}
	return val.(core.FileSystem)
}
