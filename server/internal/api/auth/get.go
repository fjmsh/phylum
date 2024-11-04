package auth

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
)

const keyUser = "user"
const keyFileSystem = "filesystem"

func GetUser(c *gin.Context) user.User {
	val, ok := c.Get(keyUser)
	if !ok {
		return user.User{}
	}
	return val.(user.User)
}

func GetFileSystem(c *gin.Context) fs.FileSystem {
	val, ok := c.Get(keyFileSystem)
	if !ok {
		return nil
	}
	return val.(fs.FileSystem)
}
