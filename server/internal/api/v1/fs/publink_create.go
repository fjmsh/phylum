package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type publinkParams struct {
	Username    string        `json:"username" binding:"required"`
	Permissions fs.Permission `json:"permission" binding:"required"`
}

func handlePublinkCreateRequest(c *gin.Context) {
	var params shareParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.Username == "" {
		panic(errInvalidParams)
	}

	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}

	r, err = r.UpdatePermissions(params.Username, params.Permissions)
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{})
}
