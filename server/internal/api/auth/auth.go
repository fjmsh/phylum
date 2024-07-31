package auth

import "github.com/gin-gonic/gin"

func GetUsername(c *gin.Context) (any, bool) {
	return c.Get(keyUsername)
}
