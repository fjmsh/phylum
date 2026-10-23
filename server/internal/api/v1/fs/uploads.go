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
	// Needed to be able to retreive the created resource
	if id == uuid.Nil {
		id, _ = uuid.NewV7()
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

		return f.CreateFileByPath(params.Path, id, versionID, src, params.Conflict)
	}()
	if err != nil {
		panic(err)
	}

	// id may have changed if this is an overwrite
	var r core.Resource
	if params.Conflict == core.ResourceBindConflictResolutionOverwrite || params.Conflict == core.ResourceBindConflictResolutionDelete {
		r, err = f.ResourceByPathWithRoot(params.Path)
	} else {
		r, err = f.ResourceByID(id)

	}
	if err != nil {
		panic(err)
	}
	c.JSON(200, responses.ResourceFromFS(r))
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
		"id": id,
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
	err = func() error {
		src, cleanup, err := f.PartialUploadOpenRead(authenticator.GetAuth(c).UserID(), uploadID)
		if err != nil {
			return err
		}
		defer src.Close()

		if err := f.CreateFileByPath(params.Path, resourceID, versionID, src, params.Conflict); err != nil {
			return err
		}
		cleanup()
		return nil
	}()
	if err != nil {
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
