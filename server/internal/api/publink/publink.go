package publink

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func Setup(r *gin.RouterGroup) {
	// r.Handle("OPTIONS", "/:id/*path", handler.HandleRequest)
	r.Handle("GET", "/:name/*path", func(c *gin.Context) {
		name := c.Param("name")
		path := c.Param("path")

		_, password, _ := c.Request.BasicAuth()
		r, err := fs.OpenFromPublink(c.Request.Context(), name, password, path)
		if err != nil {
			if errors.Is(err, fs.ErrInsufficientPermissions) {
				c.Header("WWW-Authenticate", "Basic realm=\""+name+"\"")
				c.AbortWithStatus(http.StatusUnauthorized)
			} else if errors.Is(err, fs.ErrResourceNotFound) {
				c.AbortWithStatus(http.StatusNotFound)
			} else {
				c.AbortWithStatus(http.StatusInternalServerError)
			}
		} else {
			serve.Serve(c.Writer, c.Request, r)
		}
	})
}
