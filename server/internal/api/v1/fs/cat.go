package fs

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func handleCatRequest(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	f := auth.GetFileSystem(c)
	r, err := f.ResourceByID(resourceID)
	if r.FSDir() {
		err = fs.ErrResourceCollection
	}
	if err != nil {
		panic(err)
	}
	serve.Serve(c.Writer, c.Request, r)
}
