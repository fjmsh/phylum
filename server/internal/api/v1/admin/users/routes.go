package users

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

var errInvalidParams = core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/users")
	group.GET("/list", handleListRequest)
	group.POST("/add", handleCreateRequest)
}
