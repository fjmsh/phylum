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

type partialUploadsStartParams struct {
	ID     string `json:"id" form:"id" binding:"omitempty,uuid"`
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

func handlePartialUploadsStartRequest(c *gin.Context) {
	var params partialUploadsStartParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	userID := authenticator.GetAuth(c).UserID()
	f := authenticator.GetFileSystem(c)

	var id uuid.UUID
	if params.ID != "" {
		id, err = uuid.Parse(params.ID)
		if err != nil {
			panic(err)
		}
	} else {
		id, _ = uuid.NewV7()
	}
	err = f.PartialUploadCreate(userID, id, params.Size, params.SHA256)
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{
		"id": id,
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
	size, uploaded, err := f.PartialUploadQuery(userID, id)
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
	uploaded := params.Offset
	err = func() error {
		file, err := c.FormFile("contents")
		if err != nil {
			if err == http.ErrMissingFile {
				return errInvalidParams
			}
			return err
		}

		if file.Size == 0 {
			return errInvalidParams
		}
		// TODO: #perf disk I/O in tx
		src, err := file.Open()
		if err != nil {
			return err
		}
		defer src.Close()

		out, err := f.PartialUploadOpenWrite(authenticator.GetAuth(c).UserID(), id, uploaded, params.SHA256)
		if err != nil {
			return err
		}

		if written, err := io.Copy(out, src); err != nil {
			out.Close()
			return err
		} else {
			uploaded += written
			return out.Close()
		}
	}()
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{
		"uploaded": uploaded,
	})
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

	if resourceID == uuid.Nil {
		resourceID, _ = uuid.NewV7()
	}

	f := authenticator.GetFileSystem(c)
	src, err := f.PartialUploadOpenRead(authenticator.GetAuth(c).UserID(), uploadID)
	if err != nil {
		panic(err)
	}
	defer src.Close()

	out, err := f.CreateFileByPath(params.Path, resourceID, versionID, params.Conflict)
	if err != nil && !errors.Is(err, core.ErrIDConflict) {
		panic(err)
	}
	defer out.Close()

	if _, err := io.Copy(out, src); err != nil {
		panic(err)
	}

	// id may have changed if this is an overwrite
	var r core.Resource
	if params.Conflict == core.ResourceBindConflictResolutionOverwrite || params.Conflict == core.ResourceBindConflictResolutionDelete {
		r, err = f.ResourceByPathWithRoot(params.Path)
	} else {
		r, err = f.ResourceByID(resourceID)

	}
	if err != nil {
		panic(err)
	}
	c.JSON(200, responses.ResourceFromFS(r))
}
