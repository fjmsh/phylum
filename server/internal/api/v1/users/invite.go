package users

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
)

type inviteParams struct {
	Email        string `json:"email" form:"email" binding:"required"`
	Name         string `json:"name" form:"name"`
	NoCreateHome bool   `json:"no_create_home" form:"no_create_home"`
	NoSendEmail  bool   `json:"no_send_email" form:"no_send_email"`
}

func handleInviteRequest(c *gin.Context) {
	var params inviteParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	u := authenticator.GetUser(c)
	if u.Permissions&core.PermissionUsersInvite == 0 {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to invite users"))
	}

	if user, err := core.CreateUser(db.Get(c.Request.Context()), params.Email, params.Name, params.NoCreateHome); err != nil {
		panic(err)
	} else {
		if !params.NoSendEmail {
			go func() {
				mail.SendWelcomeEmail(user)
			}()
		}
		c.JSON(200, responses.User{ID: user.ID, Email: user.Email, Name: user.Name})
	}
}
