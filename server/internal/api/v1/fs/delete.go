package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
)

type deleteParams struct {
	Path string `json:"path" form:"path" binding:"required"`
	Hard bool   `json:"permanent" form:"permanent"`
}

func handleDeleteRequest(c *gin.Context) {
	var params deleteParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPathWithMaybeRoot(params.Path)
	if err != nil {
		panic(err)
	}
	if r, err := r.DeleteRecursive(!params.Hard); err != nil {
		panic(err)
	} else if !params.Hard {
		c.JSON(200, responses.ResourceFromFS(r))
	} else {
		c.JSON(200, gin.H{"deleted": r.ID().String()})
	}
}
