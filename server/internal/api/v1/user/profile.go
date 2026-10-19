package user

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type profileUpdateParams struct {
	Name string `json:"name" form:"name"`
}

func handleProfileUpdateRoute(c *gin.Context) {
	var params profileUpdateParams
	err := c.Bind(&params)
	if err != nil {
		panic(err)
	}

	auth := authenticator.GetAuth(c)

	var user core.User
	err = db.Get(c.Request.Context()).RunInTx(func(db db.TxHandler) error {
		if params.Name != "" {
			if user, err = core.UpdateUserName(db, auth.UserID(), params.Name); err != nil {
				return err
			}
		}
		return nil
	})

	if err != nil {
		panic(err)
	}
	c.JSON(200, responses.User{
		ID:    user.ID,
		Email: user.Email,
		Name:  user.Name,
	})
}
