package authenticator

import (
	"github.com/gin-gonic/gin"
)

const keyAPIKey = "api_key"

func GetAPIKey(c *gin.Context) string {
	val, ok := c.Get(keyAPIKey)
	if !ok {
		return ""
	}
	return val.(string)
}

func RequireAPIKey(c *gin.Context) {
	if header := c.Request.Header.Get("Authorization"); header == "" {
		panic(errAuthRequired)
	} else if apiKey, ok := checkAuthHeader(header, "api-key"); !ok {
		panic(errAuthRequired)
	} else {
		c.Set(keyAPIKey, apiKey)
	}
}
