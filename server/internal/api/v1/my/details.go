package my

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/user"
)

type detailsParams struct {
	DisplayName string `json:"display_name" form:"display_name"`
}

func handleDetailsUpdateRoute(c *gin.Context) {
	var params detailsParams
	err := c.Bind(&params)
	if err != nil {
		panic(err)
	}

	u := authenticator.GetUser(c)

	err = db.Get(c.Request.Context()).RunInTx(func(d db.Handler) error {
		userManager := user.ManagerFromDB(d)
		if params.DisplayName != "" {
			if err := userManager.UpdateUserDisplayName(u, params.DisplayName); err != nil {
				return err
			}
			u.DisplayName = params.DisplayName
		}
		return nil
	})

	if err != nil {
		panic(err)
	}
	c.JSON(200, responses.User{
		ID:          u.ID,
		Email:       u.Email,
		DisplayName: u.DisplayName,
	})
}
