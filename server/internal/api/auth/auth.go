package auth

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/app/core"
)

const keyFileSystem = "filesystem"
const keyUserID = "userID"

func GetUserID(c *gin.Context) int32 {
	val, ok := c.Get(keyUserID)
	if !ok {
		return 0
	}
	return val.(int32)
}

func GetFileSystem(c *gin.Context) core.FileSystem {
	val, ok := c.Get(keyFileSystem)
	if !ok {
		return nil
	}
	return val.(core.FileSystem)
}
