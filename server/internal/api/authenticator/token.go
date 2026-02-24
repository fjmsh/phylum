package authenticator

import (
	"codeberg.org/shroff/phylum/server/internal/auth"
	"github.com/gin-gonic/gin"
)

const keyAPIToken = "api_token"

func GetAPIToken(c *gin.Context) string {
	val, ok := c.Get(keyAPIToken)
	if !ok {
		return ""
	}
	return val.(string)
}

func RequireAPIToken(c *gin.Context) {
	if header := c.Request.Header.Get("Authorization"); header == "" {
		panic(errAuthRequired)
	} else if authHeader, ok := checkAuthHeader(header, "basic"); ok {
		if keyIDStr, keyStr, ok := decodeBasicAuth(authHeader); ok {
			if keyIDStr == "" {
				c.Set(keyAPIToken, keyStr)
			} else if token, err := auth.APIKeyToToken(keyIDStr, keyStr); err == nil {
				c.Set(keyAPIToken, token)
			} else {
				panic(err)
			}
		}
	} else if encodedKey, ok := checkAuthHeader(header, "bearer"); ok {
		c.Set(keyAPIToken, encodedKey)
	}
}
