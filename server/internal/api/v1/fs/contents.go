package fs

import (
	"archive/zip"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/core/errors"
)

var errGetCollectionContents = errors.NewError(http.StatusBadRequest, "resource_is_collection", "Cannot get contents of collection")

func handleContentsRequest(c *gin.Context) {
	// Trim leading '/'
	path := c.Param("path")[1:]
	versionIDStr := c.Query("version")

	f := authenticator.GetFileSystem(c)
	r, err := f.ResourceByPathWithRoot(path)
	if err != nil {
		panic(err)
	}

	download := c.Request.URL.Query().Has("download")
	if download {
		name := c.Request.URL.Query().Get("name")
		if name == "" {
			name = r.Name()
		}
		if r.Dir() {
			name += ".zip"
			c.Writer.Header().Set("Content-Type", "application/zip")
		}
		c.Writer.Header().Set("Content-Disposition", "attachment; filename=\""+name+"\"")
	}
	if r.Dir() {

	} else {
		versionID := r.LatestVersion().ID
		if versionIDStr != "" {
			var err error
			versionID, err = uuid.Parse(versionIDStr)
			if err != nil {
				panic(err)
			}
		}
		serve.ServeResourceVersion(c.Writer, c.Request, f, r, versionID)
		return
	}

	if !download {
		panic(errGetCollectionContents)
	}

	c.Writer.Header().Set("Content-Type", "application/zip")

	var zip = zip.NewWriter(c.Writer)
	close := c.Writer.CloseNotify()
	err = f.Walk(r, 2, func(r core.Resource, p string) error {
		if r.Dir() {
			return nil
		}

		select {
		case <-close:
			return nil
		default:
		}

		out, err := zip.Create(p)
		if err != nil {
			return err
		}
		in, err := f.OpenRead(0, -1, r, uuid.Nil)
		if err != nil {
			return err
		}
		_, copyErr := io.Copy(out, in)
		closeErr := in.Close()

		if copyErr != nil {
			return copyErr
		}
		if closeErr != nil {
			return closeErr
		}
		if err := zip.Flush(); err != nil {
			return err
		}
		return nil
	})
	closeErr := zip.Close()
	if err != nil {
		panic(err)
	}
	if closeErr != nil {
		panic(closeErr)
	}
}
