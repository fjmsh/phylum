package fs

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type copyParams struct {
	Src       string                              `json:"src" form:"src" binding:"required"`
	Dest      string                              `json:"dest" form:"dest" binding:"required"`
	ID        uuid.UUID                           `json:"id" form:"id"`
	VersionID uuid.UUID                           `json:"version_id" form:"id"`
	Conflict  core.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
}

func handleCopyRequest(c *gin.Context) {
	var params copyParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	fs := authenticator.GetFileSystem(c)
	src, err := fs.ResourceByPath(params.Src)
	if err != nil {
		panic(err)
	}
	if params.ID == uuid.Nil {
		params.ID, _ = uuid.NewV7()
	}

	if r, _, err := fs.Copy(src, params.Dest, params.ID, true, params.Conflict); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.ResourceFromFS(r))
	}
}
