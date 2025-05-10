package fs

import (
	"archive/zip"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/errors"
	"github.com/shroff/phylum/server/internal/core/fs"
)

var errGetCollectionContents = errors.NewError(http.StatusBadRequest, "resource_is_collection", "Cannot get contents of collection")

func handleContentsRequest(c *gin.Context) {
	path := c.Param("path")

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
		}
		c.Writer.Header().Set("Content-Disposition", "attachment; filename=\""+name+"\"")
		c.Writer.Header().Set("Content-Type", r.ContentType())
	}
	if !r.Dir() {
		serve.Serve(c.Writer, c.Request, r)
		return
	}
	if !download {
		panic(errGetCollectionContents)
	}

	c.Writer.Header().Set("Content-Type", "application/zip")

	var zip = zip.NewWriter(c.Writer)
	close := c.Writer.CloseNotify()
	err = r.Walk(2, func(r fs.Resource, p string) error {
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
		in, err := r.OpenRead(0, -1)
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
