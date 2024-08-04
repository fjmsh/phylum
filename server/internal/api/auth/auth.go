package auth

import "github.com/gin-gonic/gin"

const keyUserID = "userID"

func GetUserID(c *gin.Context) int32 {
	val, ok := c.Get(keyUserID)
	if !ok {
		return 0
	}
	return val.(int32)
}
