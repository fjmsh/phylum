package users

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/shroff/phylum/server/internal/mail"
)

type inviteParams struct {
	Email        string `json:"email" form:"email" binding:"required"`
	DisplayName  string `json:"display_name" form:"display_name"`
	NoCreateHome bool   `json:"no_create_home" form:"no_create_home"`
	NoSendEmail  bool   `json:"no_send_email" form:"no_send_email"`
}

var errInvalidParams = errors.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

func handleInviteRequest(c *gin.Context) {
	var params inviteParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	userManager := user.ManagerFromContext(c.Request.Context())
	homePath := "/home/" + params.Email
	if params.NoCreateHome {
		homePath = ""
	}
	if user, err := userManager.CreateUser(params.Email, params.DisplayName, homePath); err != nil {
		panic(err)
	} else {
		if !params.NoSendEmail {
			go func() {
				mail.SendWelcomeEmail(user)
			}()
		}
		c.JSON(200, responses.User{ID: user.ID, Email: user.Email, DisplayName: user.DisplayName})
	}
}
