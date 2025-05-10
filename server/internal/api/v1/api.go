package apiv1

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/api/v1/auth"
	"github.com/shroff/phylum/server/internal/api/v1/fs"
	"github.com/shroff/phylum/server/internal/api/v1/my"
	"github.com/shroff/phylum/server/internal/api/v1/publinks"
	"github.com/shroff/phylum/server/internal/api/v1/trash"
	"github.com/shroff/phylum/server/internal/api/v1/users"
)

func Setup(r *gin.RouterGroup) {
	// Unauthenticated routes
	auth.SetupRoutes(r)

	// Authenticated routes
	r.Use(authenticator.Require)
	fs.SetupRoutes(r)
	my.SetupRoutes(r)
	publinks.SetupRoutes(r)
	trash.SetupRoutes(r)
	users.SetupUserRoutes(r)
}
