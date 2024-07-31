package api

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/app"
)

func Setup(r *gin.RouterGroup, a *app.App) {
	// Unauthenticated routes
	setupAuthRoutes(r, a)

	// Authenticated routes
	r.Use(auth.CreateBearerAuthHandler(a))
	setupSiloRoutes(r, a)
	setupResourceRoutes(r, a)
}

func setupResourceRoutes(r *gin.RouterGroup, a *app.App) {
	group := r.Group("/resources")
	group.GET("/:id/metadata")
	group.PUT("/:id/metadata")
	group.GET("/:id/contents")
	group.PUT("/:id/contents")
}
