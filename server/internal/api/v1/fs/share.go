package fs

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
)

type shareParams struct {
	Path       string                  `json:"path" form:"path" binding:"required"`
	Email      string                  `json:"email" form:"email" binding:"required"`
	Permission core.ResourcePermission `json:"permission" form:"permission"`
}

func handleShareRequest(c *gin.Context) {
	var params shareParams
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

	user, err := core.UserByEmail(db.Get(c.Request.Context()), params.Email)
	if err != nil {
		panic(err)
	}

	r, err = fs.UpdatePermissions(r, user, params.Permission)
	if err != nil {
		panic(err)
	}
	go func() {
		mail.SendResourceShareEmail(user, r)
	}()

	c.JSON(200, responses.ResourceFromFS(r))
}
