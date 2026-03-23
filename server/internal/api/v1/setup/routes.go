package setup

import "github.com/gin-gonic/gin"

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/setup")

	group.POST("/validate/db", handleValidateDBRequest)
}
