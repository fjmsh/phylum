package fs

import (
	"io"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func handleUploadRequest(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	name := c.Request.FormValue("name")
	parentID, err := uuid.Parse(c.Request.FormValue("parent_id"))
	if err != nil || name == "" {
		panic(errInvalidParams)
	}
	conflict, err := strconv.Atoi(c.Request.FormValue("conflict"))
	if err != nil || name == "" {
		panic(errInvalidParams)
	}
	// TODO: Calculate and verify sha sum
	// c.Request.FormValue("sha256sum")

	f := auth.GetFileSystem(c)
	err = f.RunInTx(func(f fs.FileSystem) error {
		parent, err := f.ResourceByID(parentID)
		if err != nil {
			return err
		}

		res, err := parent.CreateMemberResource(name, resourceID, false, fs.ResourceBindConflictResolution(conflict))
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
	r, err := f.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}
	c.JSON(200, ResponseFromResourceInfo(r.Info))
}
