package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
)

type mkdirParams struct {
	Name     string    `json:"name" binding:"required"`
	ParentID uuid.UUID `json:"parent_id" binding:"required"`
}

func handleMkdirRequest(c *gin.Context) {
	var params mkdirParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.Name == "" {
		panic(errInvalidParams)
	}

	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	parent, err := fs.ResourceByID(params.ParentID)
	if err != nil {
		panic(err)
	}

	r, err := parent.CreateMemberResource(params.Name, resourceID, true)
	if err != nil {
		panic(err)
	}

	c.JSON(200, createInfo(r.Info))
}
