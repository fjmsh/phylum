package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type mvParams struct {
	Target   string                            `json:"target"`
	Conflict fs.ResourceBindConflictResolution `json:"conflict"`
}

func handleMvRequest(c *gin.Context) {
	var params mvParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
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

	if r, _, err := r.Move(params.Target, params.Conflict); err != nil {
		panic(err)
	} else {
		c.JSON(200, ResponseFromResourceInfo(r.Info))
	}
}
