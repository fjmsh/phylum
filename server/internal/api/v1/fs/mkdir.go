package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type mkdirParams struct {
	Parent   string                            `json:"parent" form:"parent" binding:"required"`
	Name     string                            `json:"name" form:"name" binding:"required"`
	ID       uuid.UUID                         `json:"id" form:"id"`
	Conflict fs.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
}

func handleMkdirRequest(c *gin.Context) {
	var params mkdirParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	fs := authenticator.GetFileSystem(c)
	parent, err := fs.ResourceByPathWithMaybeRoot(params.Parent)
	if err != nil {
		panic(err)
	}

	if params.ID == uuid.Nil {
		params.ID, _ = uuid.NewV7()
	}

	r, err := parent.CreateMemberResource(params.Name, params.ID, true, params.Conflict)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.ResourceFromFS(r))
}
