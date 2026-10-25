package fs

import (
	"net/http"
	"strings"

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
	group.GET("/tree/*path", handleTreeRequest)
	group.GET("/contents/*path", handleContentsRequest)
	group.GET("/img/*path", handleImgRequest)
	group.GET("/disk_usage/*path", handleDiskUsageRequest)

	group.POST("/share", handleShareRequest)
	group.POST("/move", handleMoveRequest)
	group.POST("/copy", handleCopyRequest)
	group.POST("/delete", handleDeleteRequest)
	group.POST("/delete_version", handleDeleteVersionRequest)

	group.POST("/mkdir", handleMkdirRequest)

	uploads := group.Group("/uploads")
	uploads.PUT("/single", handleUploadsSingleRequest)
	uploads.POST("/start", handleUploadsStartRequest)
	uploads.GET("/query", handleUploadsQueryRequest)
	uploads.PUT("/chunk", handleUploadsUploadRequest)
	uploads.POST("/finalize", handleUploadsFinalizeRequest)

	group.GET("/search", handleSearchRequest)
}

// fixPath takes a path and makes sure it begins with a valid path root
// One of '/', '~', and ':'
func fixPath(path string) string {
	path = strings.TrimLeft(path, "/")
	if len(path) > 0 && (path[0] == '~' || path[0] == ':') {
		return path
	}
	return "/" + path
}
