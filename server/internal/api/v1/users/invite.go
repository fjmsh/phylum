package users

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core"
	core1 "github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/mail"
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

	userManager := core.UserManagerFromContext(c.Request.Context())
	u := authenticator.GetUser(c)

	if u.Permissions&core.PermissionUsersInvite == 0 {
		panic(core1.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to invite users"))
	}

	if user, err := userManager.CreateUser(params.Email, params.Name, params.NoCreateHome); err != nil {
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
