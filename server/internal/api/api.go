package api

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/api/routes"
	"github.com/shroff/phylum/server/internal/app"
)

func Setup(r *gin.RouterGroup, a *app.App) {
	r.Use(handleApiError)

	// Unauthenticated routes
	routes.SetupAuthRoutes(r, a)

	// Authenticated routes
	r.Use(auth.CreateBearerAuthHandler(a))
	routes.SetupResourceRoutes(r)
}

func handleApiError(c *gin.Context) {
	defer func() {
		if err := recover(); err != nil {
			if e, ok := err.(*errors.Err); ok {
				c.AbortWithStatusJSON(e.Status, e)
			} else {
				panic(err)
			}
		}
	}()
	c.Next()
}
