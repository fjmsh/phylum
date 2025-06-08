package fs

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

type moveParams struct {
	Src      string                              `json:"src" form:"src" binding:"required"`
	Dest     string                              `json:"dest" form:"dest" binding:"required"`
	Conflict core.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
}

func handleMoveRequest(c *gin.Context) {
	var params moveParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPathWithRoot(params.Src)
	if err != nil {
		panic(err)
	}

	if r, _, err := fs.Move(r, params.Dest, params.Conflict); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.ResourceFromFS(r))
	}
}
