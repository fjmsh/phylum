package fs

import (
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type uploadParams struct {
	Parent   string                            `json:"parent" form:"parent" binding:"required"`
	Name     string                            `json:"name" form:"name" binding:"required"`
	ID       uuid.UUID                         `json:"id" form:"id"`
	Conflict fs.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
	SHA256   string                            `json:"sha256" form:"sha256"`
}

func handleUploadRequest(c *gin.Context) {
	var params uploadParams
	c.BindQuery(&params)

	// TODO: Calculate and verify sha sum
	// c.Request.FormValue("sha256sum")
	if params.ID == uuid.Nil {
		params.ID, _ = uuid.NewV7()
	}

	f := authenticator.GetFileSystem(c)
	err := f.RunInTx(func(f fs.FileSystem) error {
		parent, err := f.ResourceByRootedPath(params.Parent)
		if err != nil {
			return err
		}

		res, err := parent.CreateMemberResource(params.Name, params.ID, false, fs.ResourceBindConflictResolution(params.Conflict))
		if err != nil {
			return err
		}

		file, err := c.FormFile("contents")
		if err != nil {
			if err == http.ErrMissingFile {
				return errInvalidParams
			}
			return err
		}

		// TODO: #perf disk I/O in tx
		src, err := file.Open()
		if err != nil {
			return err
		}
		defer src.Close()

		out, err := res.OpenWrite()
		if err != nil {
			return err
		}
		defer out.Close()

		_, err = io.Copy(out, src)
		return err
	})
	if err != nil {
		panic(err)
	}

	// TODO: Avoid reading from db again if we can update size and etag
	r, err := f.ResourceByID(params.ID)
	if err != nil {
		panic(err)
	}
	c.JSON(200, responses.ResourceFromFS(r))
}
