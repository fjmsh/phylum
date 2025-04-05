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
	permanent := c.Request.URL.Query().Has("permanent")

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(id)
	if err != nil {
		panic(err)
	}
	if r, err := r.DeleteRecursive(!permanent); err != nil {
		panic(err)
	} else if !permanent {
		c.JSON(200, responses.ResourceFromFS(r))
	} else {
		c.JSON(200, gin.H{"deleted": id.String()})
	}
}
