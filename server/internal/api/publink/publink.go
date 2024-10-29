package publink

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/publink"
)

func Setup(r *gin.RouterGroup) {
	// r.Handle("OPTIONS", "/:id/*path", handler.HandleRequest)
	r.Handle("GET", "/:name/*path", func(c *gin.Context) {
		name := c.Param("name")
		path := c.Param("path")

		_, password, _ := c.Request.BasicAuth()
		r, err := publink.OpenResource(c.Request.Context(), name, password, path)
		if err != nil {
			if errors.Is(err, auth.ErrRequired) {
				c.Header("WWW-Authenticate", "Basic realm=\""+name+"\"")
			}
			panic(err)
		}
		serve.Serve(c.Writer, c.Request, r)
	})
}
