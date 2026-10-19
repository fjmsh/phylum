package mail

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

var errInvalidParams = core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/mail")
	group.GET("/read", handleReadRequest)
	group.POST("/update", handleUpdateRequest)
}

func handleReadRequest(c *gin.Context) {
	c.JSON(http.StatusOK, config.ConfigMap("mail"))
}
