package publink

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func Setup(r *gin.RouterGroup) {
	r.Handle("GET", "/:id/*path", func(c *gin.Context) {
		id := c.Param("id")
		path := c.Param("path")

		_, password, _ := c.Request.BasicAuth()
		f, err := fs.OpenFromPublink(c.Request.Context(), id, password)
		if err != nil {
			if errors.Is(err, fs.ErrInsufficientPermissions) {
				c.Header("WWW-Authenticate", "Basic realm=\""+id+"\"")
				c.AbortWithStatus(http.StatusUnauthorized)
			} else if errors.Is(err, fs.ErrResourceNotFound) {
				c.AbortWithStatus(http.StatusNotFound)
			} else {
				c.AbortWithStatus(http.StatusInternalServerError)
			}
		} else if r, err := f.ResourceByPath(path); err != nil {
			if errors.Is(err, fs.ErrResourceNotFound) {
				c.AbortWithStatus(http.StatusNotFound)
			} else {
				c.AbortWithStatus(http.StatusInternalServerError)
			}
		} else {
			c.Writer.Header().Set("Content-Disposition", "attachment; filename=\""+r.Name()+"\"")
			serve.Serve(c.Writer, c.Request, f, r)
		}
	})
}
