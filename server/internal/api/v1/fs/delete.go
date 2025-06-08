package fs

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"github.com/gin-gonic/gin"
)

type deleteParams struct {
	Path string `json:"path" form:"path" binding:"required"`
	Hard bool   `json:"permanent" form:"permanent"`
}

func handleDeleteRequest(c *gin.Context) {
	var params deleteParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPathWithRoot(params.Path)
	if err != nil {
		panic(err)
	}
	if r, err := fs.DeleteRecursive(r, !params.Hard); err != nil {
		panic(err)
	} else if !params.Hard {
		c.JSON(200, responses.ResourceFromFS(r))
	} else {
		c.JSON(200, gin.H{"deleted": r.ID().String()})
	}
}
