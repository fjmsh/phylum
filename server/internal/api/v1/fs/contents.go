package fs

import (
	"archive/zip"
	"io"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/serve"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

func handleContentsRequest(c *gin.Context) {
	path := fixPath(c.Param("path"))
	versionIDStr := c.Query("version")

	f := authenticator.GetFileSystem(c)
	r, err := f.ResourceByPath(path)
	if err != nil {
		panic(err)
	}

	if !r.Dir() {
		serve.ServeResourceVersion(c.Writer, c.Request, f, r, versionIDStr)
		return
	}

	c.Writer.Header().Set("Content-Type", "application/zip")
	c.Writer.Header().Set("Content-Disposition", "attachment; filename=\""+r.Name()+".zip\"")

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

		v, err := f.GetVersion(r, "")
		if err != nil {
			return err
		}
		in, err := v.OpenRead(0, -1)
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
