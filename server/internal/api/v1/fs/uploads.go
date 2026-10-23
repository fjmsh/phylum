package fs

import (
	"errors"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func handleUploadsSingleRequest(c *gin.Context) {
	var params struct {
		Path          string                              `json:"path" form:"path" binding:"required"`
		ID            string                              `json:"id" form:"id" binding:"omitempty,uuid"`
		VersionID     string                              `json:"version_id" form:"version_id" binding:"omitempty,uuid"`
		CreateParents bool                                `json:"create_parents" form:"create_parents"`
		Conflict      core.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
		SHA256        string                              `json:"sha256" form:"sha256"`
	}
	err := c.ShouldBindQuery(&params)
	if err != nil {
		panic(err)
	}
	var resourceID uuid.UUID
	var versionID uuid.UUID
	if params.ID != "" {
		resourceID, err = uuid.Parse(params.ID)
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
	// Needed to be able to retreive the created resource
	if resourceID == uuid.Nil {
		resourceID, _ = uuid.NewV7()
	}

	// TODO: Calculate and verify sha sum

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

		resourceID, err = f.CreateFileByPath(params.Path, resourceID, versionID, src, params.Conflict)
		return err
	}()
	if err != nil {
		panic(err)
	} else if res, err := f.ResourceByID(resourceID); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.ResourceFromFS(res))
	}
}

func handleUploadsStartRequest(c *gin.Context) {
	var params struct {
		ID     string `json:"id" form:"id" binding:"omitempty,uuid"`
		Size   int64  `json:"size" form:"size" binding:"required"`
		SHA256 string `json:"sha256" form:"sha256"`
	}
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
		"id":       id,
		"size":     params.Size,
		"uploaded": 0,
	})
}

func handleUploadsQueryRequest(c *gin.Context) {
	var params struct {
		ID string `json:"id" form:"id" binding:"required,uuid"`
	}
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
		"id":       params.ID,
		"size":     size,
		"uploaded": uploaded,
	})
}

func handleUploadsUploadRequest(c *gin.Context) {
	var params struct {
		ID     string `json:"id" form:"id" binding:"required,uuid"`
		Offset int64  `json:"offset" form:"offset"`
		SHA256 string `json:"sha256" form:"sha256"`
	}
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

	file, err := c.FormFile("contents")
	if err != nil {
		if errors.Is(err, http.ErrMissingFile) {
			err = errInvalidParams
		}
	} else if file.Size == 0 {
		err = errInvalidParams
	}

	if err != nil {
		panic(err)
	}

	f := authenticator.GetFileSystem(c)
	src, err := file.Open()
	if err != nil {
		panic(err)
	}
	defer src.Close()

	if size, offset, err := f.PartialUploadWrite(authenticator.GetAuth(c).UserID(), id, src, params.Offset, params.SHA256); err != nil {
		panic(err)
	} else {
		c.JSON(200, gin.H{
			"id":       params.ID,
			"size":     size,
			"uploaded": offset,
		})
	}

}

func handleUploadsFinalizeRequest(c *gin.Context) {
	var params struct {
		UploadID      string                              `json:"upload_id" form:"upload_id" binding:"required,uuid"`
		Path          string                              `json:"path" form:"path" binding:"required"`
		ResourceID    string                              `json:"resource_id" form:"resource_id" binding:"omitempty,uuid"`
		VersionID     string                              `json:"version_id" form:"version_id" binding:"omitempty,uuid"`
		CreateParents bool                                `json:"create_parents" form:"create_parents"`
		Conflict      core.ResourceBindConflictResolution `json:"conflict" form:"conflict"`
	}

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
	resourceID, err = f.PartialUploadFinalize(
		authenticator.GetAuth(c).UserID(),
		uploadID,
		resourceID,
		versionID,
		params.Path,
		params.Conflict,
	)
	if err != nil {
		panic(err)
	} else if res, err := f.ResourceByID(resourceID); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.ResourceFromFS(res))
	}
}
