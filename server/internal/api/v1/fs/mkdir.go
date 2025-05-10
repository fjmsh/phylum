package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type mkdirParams struct {
	Path          string                            `json:"path" form:"path" binding:"required"`
	CreateParents bool                              `json:"create_parents" form:"create_parents"`
	ID            uuid.UUID                         `json:"id" form:"id"`
	Conflict      fs.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
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

	r, err := fs.CreateResourceByPath(params.Path, params.ID, true, params.CreateParents, params.Conflict)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.ResourceFromFS(r))
}
