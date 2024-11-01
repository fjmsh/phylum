package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type ResourceLsResponse struct {
	fs.Resource
	InheritedPermissions string           `json:"inherited,omitempty"`
	Children             []serve.Resource `json:"children,omitempty"`
}

func handleLsRequest(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}

	c.JSON(200, LsResponseFromResource(fs, r))
}

func LsResponseFromResource(f fs.FileSystem, r fs.Resource) ResourceLsResponse {
	response := ResourceLsResponse{
		Resource:             r,
		InheritedPermissions: r.FullPermissionsString(),
	}
	// if r.FSDir() {
	// 	children, err := r.ReadDir(false)
	// 	if err != nil {
	// 		panic(err)
	// 	}
	// 	response.Children = children
	// }
	return response
}
