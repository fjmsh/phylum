package apiv1

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/v1/fs"
	"github.com/shroff/phylum/server/internal/api/v1/login"
	"github.com/shroff/phylum/server/internal/api/v1/my"
	"github.com/shroff/phylum/server/internal/api/v1/users"
)

func Setup(r *gin.RouterGroup) {
	// Unauthenticated routes
	login.SetupRoutes(r)

	// Authenticated routes
	r.Use(CreateApiAuthHandler())
	fs.SetupRoutes(r)
	my.SetupRoutes(r)
	users.SetupUserRoutes(r)
}
