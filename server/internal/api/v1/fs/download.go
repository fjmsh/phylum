package fs

import (
	"archive/zip"
	"io"
	"path"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func handleDownloadRequest(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	f := auth.GetFileSystem(c)
	r, err := f.ResourceByID(resourceID)
	prefix := path.Dir(r.Path)

	c.Writer.Header().Set("Content-Type", "application/zip")
	c.Writer.Header().Set("Content-Disposition", "attachment; filename=\""+r.Name+".zip\"")

	var zip = zip.NewWriter(c.Writer)
	close := c.Writer.CloseNotify()
	err = r.Walk(2, func(r serve.Resource) error {
		if r.FSDir() {
			return nil
		}

		select {
		case <-close:
			return nil
		default:
		}

		path, found := strings.CutPrefix(r.FSPath(), prefix)
		if !found {
			return fs.ErrResourcePathInvalid
		}
		out, err := zip.Create(path)
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
