package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type shareParams struct {
	Path        string        `json:"path" form:"path" binding:"required"`
	Username    string        `json:"username" form:"username" binding:"required"`
	Permissions fs.Permission `json:"permission" form:"permissions" binding:"required"`
}

func handleShareRequest(c *gin.Context) {
	var params shareParams
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

	r, err = r.UpdatePermissions(params.Username, params.Permissions)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.ResourceFromFS(r))
}
