package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
)

func handleRmRequest(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(id)
	if err != nil {
		panic(err)
	}
	ids, err := fs.DeleteRecursive(r, false)
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{"ids": ids})
}
