package publinks

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

type deleteParams struct {
	ID string `json:"id" form:"id" binding:"required"`
}

func handleDeleteRequest(c *gin.Context) {
	var params deleteParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	auth := authenticator.GetAuth(c)
	if !auth.HasScope("publink:delete") {
		panic(core.ErrInsufficientScope)
	}

	if err := core.DeletePublink(c.Request.Context(), params.ID); err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{})
}
