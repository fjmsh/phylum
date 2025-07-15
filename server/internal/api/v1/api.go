package apiv1

import (
	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/auth"
	"codeberg.org/shroff/phylum/server/internal/api/v1/fs"
	"codeberg.org/shroff/phylum/server/internal/api/v1/my"
	"codeberg.org/shroff/phylum/server/internal/api/v1/publinks"
	"codeberg.org/shroff/phylum/server/internal/api/v1/trash"
	"codeberg.org/shroff/phylum/server/internal/api/v1/users"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func Setup(r *gin.RouterGroup, logger *zerolog.Logger) {
	// Unauthenticated routes
	auth.SetupRoutes(r, logger)

	// Authenticated routes
	r.Use(authenticator.Require)
	fs.SetupRoutes(r)
	my.SetupRoutes(r)
	publinks.SetupRoutes(r)
	trash.SetupRoutes(r)
	users.SetupUserRoutes(r)
}
