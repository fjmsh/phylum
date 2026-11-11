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
	Path         string                  `json:"path" form:"path" binding:"required"`
	UserID       int32                   `json:"user_id" form:"user_id"`
	UserEmail    string                  `json:"user_email" form:"user_email"`
	ShareWithAll bool                    `json:"share_with_all" form:"share_with_all"`
	Permission   core.ResourcePermission `json:"permission" form:"permission"`
}

func handleShareRequest(c *gin.Context) {
	var params shareParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPath(params.Path)
	if err != nil {
		panic(err)
	}

	var user core.User
	if params.UserID != 0 {
		user, err = core.UserByID(db.Get(c.Request.Context()), params.UserID)
	} else if params.UserEmail != "" {
		user, err = core.UserByEmail(db.Get(c.Request.Context()), params.UserEmail)
	} else if !params.ShareWithAll {
		err = errInvalidParams
	}
	if err != nil {
		panic(err)
	}

	// It is valid for user.ID to be 0, and is expected to be the case when params.ShareWithAll is set
	r, err = fs.UpdatePermissions(r, user.ID, params.Permission)
	if err != nil {
		panic(err)
	}
	if user.ID != 0 {
		go func() {
			mail.SendResourceShareEmail(user, r)
		}()
	}

	c.JSON(200, responses.ResourceFromFS(r))
}
