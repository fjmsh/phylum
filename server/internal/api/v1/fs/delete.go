package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
)

func handleDeleteRequest(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(id)
	if err != nil {
		panic(err)
	}
	if r, err := r.DeleteRecursive(true); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.ResourceFromFS(r))
	}
}
