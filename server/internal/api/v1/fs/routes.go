package fs

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core/errors"
)

var (
	errResourceIDInvalid = errors.NewError(http.StatusBadRequest, "resource_id_invalid", "Invalid UUID")
	errInvalidParams     = errors.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")
)

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/fs")
	group.GET("/contents/:id", handleContentsRequest)
	group.GET("/du/:id", handleDuRequest)
	group.GET("/ls/:id", handleLsRequest)
	group.POST("/mkdir/:id", handleMkdirRequest)
	group.POST("/mv/:id", handleMvRequest)
	group.POST("/cp/:id", handleCpRequest)
	group.GET("/publink/:id/list", handlePublinkListRequest)
	group.POST("/publink/:id/create", handlePublinkCreateRequest)
	group.DELETE("/rm/:id", handleRmRequest)
	group.POST("/share/:id", handleShareRequest)
	group.PUT("/upload/:id", handleUploadRequest)
}
