package my

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type detailsParams struct {
	Name string `json:"name" form:"name"`
}

func handleDetailsUpdateRoute(c *gin.Context) {
	var params detailsParams
	err := c.Bind(&params)
	if err != nil {
		panic(err)
	}

	u := authenticator.GetUser(c)

	err = db.Get(c.Request.Context()).RunInTx(func(db db.Handler) error {
		if params.Name != "" {
			if err := core.UpdateUserName(db, u, params.Name); err != nil {
				return err
			}
			u.Name = params.Name
		}
		return nil
	})

	if err != nil {
		panic(err)
	}
	c.JSON(200, responses.User{
		ID:    u.ID,
		Email: u.Email,
		Name:  u.Name,
	})
}
