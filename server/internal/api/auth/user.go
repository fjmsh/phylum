package auth

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/fs"
)

const keyUser = "user"
const keyFileSystem = "filesystem"

func GetUser(c *gin.Context) app.User {
	val, ok := c.Get(keyUser)
	if !ok {
		return app.User{}
	}
	return val.(app.User)
}

func GetFileSystem(c *gin.Context) fs.FileSystem {
	val, ok := c.Get(keyFileSystem)
	if !ok {
		return nil
	}
	return val.(fs.FileSystem)
}
