package fs

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

var (
	errResourceIDInvalid = core.NewError(http.StatusBadRequest, "resource_id_invalid", "Invalid UUID")
	errInvalidParams     = core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")
)

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/fs")

	group.GET("/info/*path", handleInfoRequest)
	group.GET("/contents/*path", handleContentsRequest)
	group.GET("/img/*path", handleImgRequest)
	group.GET("/disk_usage/*path", handleDiskUsageRequest)

	group.POST("/share", handleShareRequest)
	group.POST("/move", handleMoveRequest)
	group.POST("/copy", handleCopyRequest)
	group.POST("/delete", handleDeleteRequest)

	group.POST("/mkdir", handleMkdirRequest)
	group.PUT("/upload", handleUploadRequest)

	group.GET("/search", handleSearchRequest)
}
