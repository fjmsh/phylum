package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
)

type shareParams struct {
	Path        string        `json:"path" form:"path" binding:"required"`
	Email       string        `json:"email" form:"email" binding:"required"`
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
	r, err := fs.ResourceByPathWithRoot(params.Path)
	if err != nil {
		panic(err)
	}

	user, err := user.ManagerFromContext(c).UserByEmail(params.Email)
	if err != nil {
		panic(err)
	}

	r, err = r.UpdatePermissions(user.ID, params.Permissions)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.ResourceFromFS(r))
}
