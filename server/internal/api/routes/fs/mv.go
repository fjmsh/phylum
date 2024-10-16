package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
)

type mvParams struct {
	ParentID  uuid.UUID `json:"parent_id"`
	Name      string    `json:"name"`
	Overwrite bool      `json:"overwrite"`
}

func handleMvRequest(c *gin.Context) {
	var params mvParams
	err := c.ShouldBindJSON(&params)
	if err != nil || (params.ParentID == uuid.Nil && params.Name == "") {
		panic(errInvalidParams)
	}

	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}

	if r, err := fs.Move(r, params.ParentID, params.Name, params.Overwrite); err != nil {
		panic(err)
	} else {
		c.JSON(200, r)
	}
}
