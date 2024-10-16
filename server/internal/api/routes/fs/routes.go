package fs

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/errors"
)

var (
	errResourceIDInvalid = errors.New(http.StatusBadRequest, "resource_id_invalid", "Invalid UUID")
	errInvalidParams     = errors.New(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")
)

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/fs")
	group.GET("/du/:id", handleDuRequest)
	group.GET("/ls/:id", handleLsRequest)
	group.POST("/mkdir/:id", handleMkdirRequest)
	group.POST("/mv/:id", handleMvRequest)
	group.DELETE("/rm/:id", handleRmRequest)
	group.PUT("/upload/:id", handleUploadRequest)
	group.GET("/cat/:id", handleCatRequest)
}
