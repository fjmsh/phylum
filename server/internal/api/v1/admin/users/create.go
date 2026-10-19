package users

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
)

type createUserParams struct {
	Email        string `json:"email" form:"email" binding:"required"`
	Name         string `json:"name" form:"name"`
	Password     string `json:"password" form:"password"`
	NoCreateHome bool   `json:"no_create_home" form:"no_create_home"`
	NoSendEmail  bool   `json:"no_send_email" form:"no_send_email"`
}

func handleCreateRequest(c *gin.Context) {
	var params createUserParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	a := authenticator.GetAuth(c)

	var u core.User
	err = db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if u, err = core.CreateUser(db, params.Email, params.Name, params.NoCreateHome); err != nil {
			return err
		}
		if auth.Get().PasswordAuthEnabled() && auth.Get().PasswordBackendSupportsUpdate() {
			if params.Password != "" {
				if err := auth.Get().UpdateUserPassword(db, params.Email, params.Password); err != nil {
					return err
				}
			}
		} else if params.Password != "" {
			panic(core.NewError(http.StatusBadRequest, "password_auth_disabled", "Attempting to set password when password auth is disabled"))
		}
		if mail.Enabled() && !params.NoSendEmail {
			// TODO: #jobs #mail
			go func() {
				mail.SendWelcomeEmail(u)
			}()
		}

		return nil
	})
	if err != nil {
		panic(err)
	}
	home := pgtype.UUID{}
	if a.UserPermissions().HasPermission(core.UserPermissionFilesRead) {
		home = u.Home
	}
	response := responses.FullUser{
		User: responses.User{
			ID:    u.ID,
			Email: u.Email,
			Name:  u.Name,
		},
		Permissions: u.Permissions,
		Home:        home,
	}
	c.JSON(200, response)
}
