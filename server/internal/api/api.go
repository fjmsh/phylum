package api

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/routes"
	"github.com/shroff/phylum/server/internal/core"
)

func Setup(r *gin.RouterGroup, a *core.App) {
	// Unauthenticated routes
	routes.SetupAuthRoutes(r, a)

	// Authenticated routes
	r.Use(auth.CreateApiAuthHandler(a))
	routes.SetupResourceRoutes(r)
	routes.SetupUserRoutes(r)
	routes.SetupMobileRoutes(r)
}
