package authenticator

import (
	"github.com/gin-gonic/gin"
)

const keyToken = "token"

func GetToken(c *gin.Context) string {
	val, ok := c.Get(keyToken)
	if !ok {
		return ""
	}
	return val.(string)
}

func RequireToken(c *gin.Context) {
	if header := c.Request.Header.Get("Authorization"); header == "" {
		panic(errAuthRequired)
	} else if token, ok := checkAuthHeader(header, "bearer"); !ok {
		panic(errAuthRequired)
	} else {
		c.Set(keyToken, token)
	}
}
