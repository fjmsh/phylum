package auth

import "github.com/gin-gonic/gin"

const keyUsername = "username"

func GetUsername(c *gin.Context) string {
	val, ok := c.Get(keyUsername)
	if !ok {
		return ""
	}
	return val.(string)
}
