package auth

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/config"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/auth")
	group.GET("/read", handleReadRequest)
	group.POST("/update", handleUpdateRequest)
	group.POST("/test/argon2", handleTestArgon2Params)
	group.POST("/test/pbkdf2", handleTestPBKDF2Params)
}

func handleReadRequest(c *gin.Context) {
	c.JSON(http.StatusOK, config.ConfigMap("auth"))
}
