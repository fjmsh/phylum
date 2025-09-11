package fs

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type deleteVersionParams struct {
	Path      string `json:"path" form:"path" binding:"required"`
	VersionID string `json:"version_id" form:"version_id" binding:"uuid"`
}

func handleDeleteVersionRequest(c *gin.Context) {
	var params deleteVersionParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	versionID, err := uuid.Parse(params.VersionID)
	if err != nil {
		panic(err)
	}

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPathWithRoot(params.Path)
	if err != nil {
		panic(err)
	}

	if r, err := fs.DeleteResourceVersion(r, versionID); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.ResourceFromFS(r))
	}
}
