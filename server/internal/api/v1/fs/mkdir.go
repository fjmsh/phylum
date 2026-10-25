package fs

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func handleMkdirRequest(c *gin.Context) {
	var params struct {
		Path          string                              `json:"path" form:"path" binding:"required"`
		CreateParents bool                                `json:"create_parents" form:"create_parents"`
		ID            uuid.UUID                           `json:"id" form:"id"`
		Conflict      core.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	fs := authenticator.GetFileSystem(c)

	r, err := fs.Mkdir(params.Path, params.ID, params.CreateParents, params.Conflict)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.ResourceFromFS(r))
}
