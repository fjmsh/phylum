package users

import (
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

	var user core.User
	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if u, err := core.CreateUser(db, params.Email, params.Name, params.NoCreateHome); err != nil {
			return err
		} else {
			user = u
			if mail.Enabled() && !params.NoSendEmail {
				// TODO: #jobs #mail
				go func() {
					mail.SendWelcomeEmail(u)
				}()
			}
			return nil
		}
	}); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.User{ID: user.ID, Email: user.Email, Name: user.Name})
	}
}
