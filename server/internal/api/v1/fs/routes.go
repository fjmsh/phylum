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
	group.GET("/info/:id", handleInfoRequest)
	group.GET("/disk_usage/:id", handleDiskUsageRequest)
	group.POST("/share/:id", handleShareRequest)
	group.POST("/move/:id", handleMoveRequest)
	group.POST("/copy/:id", handleCopyRequest)
	group.DELETE("/delete/:id", handleDeleteRequest)

	group.POST("/mkdir/:id", handleMkdirRequest)
	group.PUT("/upload/:id", handleUploadRequest)

	group.GET("/search", handleSearchRequest)

	group.GET("/publinks/:id/list", handlePublinksListRequest)
	group.POST("/publinks/:id/create", handlePublinksCreateRequest)
}
