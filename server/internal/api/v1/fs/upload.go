package fs

import (
	"io"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type uploadParams struct {
	Path          string                              `json:"path" form:"path" binding:"required"`
	ID            string                              `json:"id" form:"id" binding:"omitempty,uuid"`
	VersionID     string                              `json:"version_id" form:"version_id" binding:"omitempty,uuid"`
	CreateParents bool                                `json:"create_parents" form:"create_parents"`
	Conflict      core.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
	SHA256        string                              `json:"sha256" form:"sha256"`
}

func handleUploadRequest(c *gin.Context) {
	var params uploadParams
	err := c.ShouldBindQuery(&params)
	if err != nil {
		panic(err)
	}
	var id uuid.UUID
	var versionID uuid.UUID
	if params.ID != "" {
		id, err = uuid.Parse(params.ID)
		if err != nil {
			panic(err)
		}
	}
	if params.VersionID != "" {
		versionID, err = uuid.Parse(params.VersionID)
		if err != nil {
			panic(err)
		}
	}

	// TODO: Calculate and verify sha sum

	f := authenticator.GetFileSystem(c)
	err = f.RunInTx(func(f core.FileSystem) error {
		res, err := f.CreateResourceByPath(params.Path, id, false, params.CreateParents, params.Conflict)
		if err != nil {
			return err
		}
		id = res.ID()

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

		out, err := f.OpenWrite(res, versionID)
		if err != nil {
			return err
		}
		defer out.Close()

		if _, err := io.Copy(out, src); err != nil {
			out.Close()
			return err
		} else {
			return out.Close()
		}
	})
	if err != nil {
		panic(err)
	}

	// TODO: Avoid reading from db again if we can update size and etag
	r, err := f.ResourceByID(id)
	if err != nil {
		panic(err)
	}
	c.JSON(200, responses.ResourceFromFS(r))
}
