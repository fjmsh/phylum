package apiv1

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/v1/fs"
	"github.com/shroff/phylum/server/internal/api/v1/login"
	"github.com/shroff/phylum/server/internal/api/v1/my"
	"github.com/shroff/phylum/server/internal/api/v1/users"
	"github.com/shroff/phylum/server/internal/core/app"
)

func Setup(r *gin.RouterGroup, a *app.App) {
	// Unauthenticated routes
	login.SetupRoutes(r, a)

	// Authenticated routes
	r.Use(CreateApiAuthHandler(a))
	fs.SetupRoutes(r)
	my.SetupRoutes(r, a)
	users.SetupUserRoutes(r)
}
