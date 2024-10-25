package public

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/fs/public"
)

func requirePassword(c *gin.Context, id string) string {
	if _, pass, ok := c.Request.BasicAuth(); ok {
		return pass
	} else {
		c.Header("WWW-Authenticate", "Basic realm=\""+id+"\"")
		panic(auth.ErrRequired)
	}
}

func Setup(r *gin.RouterGroup) {
	// r.Handle("OPTIONS", "/:id/*path", handler.HandleRequest)
	r.Handle("GET", "/:id/*path", func(c *gin.Context) {
		id := c.Param("id")
		path := c.Param("path")

		r, err := public.OpenResource(c.Request.Context(), id, func() string { return requirePassword(c, id) }, path)
		if err != nil {
			panic(err)
		}
		serve.Serve(c.Writer, c.Request, r)
	})
}
