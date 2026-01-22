package fs

import (
	"io"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type partialUploadsCreateParams struct {
	Size   int64  `json:"size"`
	SHA256 string `json:"sha256" form:"sha256"`
}

type partialUploadsQueryParams struct {
	ID string `json:"id" form:"id" binding:"required,uuid"`
}

type partialUploadsUploadParams struct {
	ID          string `json:"id" form:"id" binding:"required,uuid"`
	Offset      int64  `json:"offset" form:"offset" binding:"required"`
	ChunkSHA256 int    `json:"chunk_sha256" form:"chunk_sha256"`
}

func handlePartialUploadsCreateRequest(c *gin.Context) {
	var params partialUploadsCreateParams
	err := c.ShouldBindQuery(&params)
	if err != nil {
		panic(err)
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
	err := c.ShouldBindQuery(&params)
	if err != nil {
		panic(err)
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
	err := c.ShouldBindQuery(&params)
	if err != nil {
		panic(err)
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
}
