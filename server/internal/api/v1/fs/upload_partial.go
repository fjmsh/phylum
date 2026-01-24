package fs

import (
	"errors"
	"io"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type partialUploadsCreateParams struct {
	Size   int64  `json:"size" form:"size" binding:"required"`
	SHA256 string `json:"sha256" form:"sha256"`
}

type partialUploadsQueryParams struct {
	ID string `json:"id" form:"id" binding:"required,uuid"`
}

type partialUploadsUploadParams struct {
	ID     string `json:"id" form:"id" binding:"required,uuid"`
	Offset int64  `json:"offset" form:"offset"`
	SHA256 string `json:"sha256" form:"sha256"`
}

type partialUploadsFinalizeParams struct {
	UploadID      string                              `json:"upload_id" form:"upload_id" binding:"required,uuid"`
	Path          string                              `json:"path" form:"path" binding:"required"`
	ResourceID    string                              `json:"resource_id" form:"resource_id" binding:"omitempty,uuid"`
	VersionID     string                              `json:"version_id" form:"version_id" binding:"omitempty,uuid"`
	CreateParents bool                                `json:"create_parents" form:"create_parents"`
	Conflict      core.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
}

func handlePartialUploadsCreateRequest(c *gin.Context) {
	var params partialUploadsCreateParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	userID := authenticator.GetAuth(c).UserID()
	f := authenticator.GetFileSystem(c)
	uploadID, err := f.CreatePartialUpload(userID, params.Size, params.SHA256)
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{
		"upload_id": uploadID,
	})
}

func handlePartialUploadsQueryRequest(c *gin.Context) {
	var params partialUploadsQueryParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	id, err := uuid.Parse(params.ID)
	if err != nil {
		panic(err)
	}

	userID := authenticator.GetAuth(c).UserID()
	f := authenticator.GetFileSystem(c)
	size, uploaded, err := f.QueryPartialUpload(userID, id)
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{
		"size":     size,
		"uploaded": uploaded,
	})
}

func handlePartialUploadsUploadRequest(c *gin.Context) {
	var params partialUploadsUploadParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	id, err := uuid.Parse(params.ID)
	if err != nil {
		panic(err)
	}

	f := authenticator.GetFileSystem(c)
	err = func() error {
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

		out, err := f.OpenPartialUpload(authenticator.GetAuth(c).UserID(), id, params.Offset)
		if err != nil {
			return err
		}

		if _, err := io.Copy(out, src); err != nil {
			out.Close()
			return err
		} else {
			return out.Close()
		}
	}()
	if err != nil {
		panic(err)
	}

	c.Status(200)
}

func handlePartialUploadsFinalizeRequest(c *gin.Context) {
	var params partialUploadsFinalizeParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}
	var uploadID, resourceID, versionID uuid.UUID
	if params.UploadID != "" {
		uploadID, err = uuid.Parse(params.UploadID)
		if err != nil {
			panic(err)
		}
	}
	if params.ResourceID != "" {
		resourceID, err = uuid.Parse(params.ResourceID)
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

	f := authenticator.GetFileSystem(c)
	err = func() error {
		// TODO: #perf disk I/O in tx
		src, err := f.ReadPartialUpload(authenticator.GetAuth(c).UserID(), uploadID)
		if err != nil {
			return err
		}
		defer src.Close()

		out, err := f.CreateFileByPath(params.Path, resourceID, versionID, params.Conflict)
		if err != nil {
			return err
		}

		if _, err := io.Copy(out, src); err != nil {
			out.Close()
			return err
		} else {
			return out.Close()
		}
	}()
	if err != nil && !errors.Is(err, core.ErrIDConflict) {
		panic(err)
	}

	// id may have changed if this is an overwrite
	r, err := f.ResourceByPathWithRoot(params.Path)
	if err != nil {
		panic(err)
	}
	c.JSON(200, responses.ResourceFromFS(r))
}
