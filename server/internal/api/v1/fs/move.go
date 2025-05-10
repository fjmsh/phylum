package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type moveParams struct {
	Src      string                            `json:"src" form:"src" binding:"required"`
	Dest     string                            `json:"dest" form:"dest" binding:"required"`
	Conflict fs.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
}

func handleMoveRequest(c *gin.Context) {
	var params moveParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPathWithMaybeRoot(params.Src)
	if err != nil {
		panic(err)
	}

	if r, _, err := r.Move(params.Dest, params.Conflict); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.ResourceFromFS(r))
	}
}
