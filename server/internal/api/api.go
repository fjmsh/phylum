package api

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/fs"
	"github.com/shroff/phylum/server/internal/api/login"
	"github.com/shroff/phylum/server/internal/api/my"
	"github.com/shroff/phylum/server/internal/api/users"
	"github.com/shroff/phylum/server/internal/core/app"
)

func Setup(r *gin.RouterGroup, a *app.App) {
	// Unauthenticated routes
	login.SetupRoutes(r, a)

	// Authenticated routes
	r.Use(auth.CreateApiAuthHandler(a))
	fs.SetupRoutes(r)
	my.SetupRoutes(r, a)
	users.SetupUserRoutes(r)
}
