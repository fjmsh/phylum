package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/fs"
)

const keyUser = "user"
const keyFileSystem = "filesystem"

var ErrRequired = errors.NewError(http.StatusUnauthorized, "auth_required", "authorization required")

func Set(c *gin.Context, u app.User, f fs.FileSystem) {
	c.Set(keyUser, u)
	c.Set(keyFileSystem, f)
}

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
