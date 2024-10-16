package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core"
)

type ResourceLsResponse struct {
	Metadata             core.Resource   `json:"metadata"`
	Children             []core.Resource `json:"children,omitempty"`
	InheritedPermissions string          `json:"inherited,omitempty"`
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

func LsResponseFromResource(fs core.FileSystem, r core.Resource) ResourceLsResponse {
	response := ResourceLsResponse{
		Metadata:             r,
		InheritedPermissions: r.InheritedPermissions,
	}
	if r.Dir {
		children, err := fs.ReadDir(r)
		if err != nil {
			panic(err)
		}
		response.Children = make([]core.Resource, len(children))
		for i, c := range children {
			response.Children[i] = c
		}
	}
	return response
}
