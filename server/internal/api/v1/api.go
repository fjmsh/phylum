package apiv1

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/admin"
	"codeberg.org/shroff/phylum/server/internal/api/v1/auth"
	"codeberg.org/shroff/phylum/server/internal/api/v1/fs"
	"codeberg.org/shroff/phylum/server/internal/api/v1/publinks"
	"codeberg.org/shroff/phylum/server/internal/api/v1/setup"
	"codeberg.org/shroff/phylum/server/internal/api/v1/trash"
	"codeberg.org/shroff/phylum/server/internal/api/v1/user"
	"codeberg.org/shroff/phylum/server/internal/api/v1/users"
	"codeberg.org/shroff/phylum/server/internal/config"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func Setup(r *gin.RouterGroup, needsSetup bool, logger *zerolog.Logger) {
	if needsSetup {
		r.GET("/info", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"setup": gin.H{
					"overrides": config.Overrides([]string{"db", "mail", "auth"}),
				},
			})
		})
		setup.SetupRoutes(r)
	} else {
		r.GET("/info", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"needs_config": false,
				"auth":         auth.ConfigResponse,
			})
		})

		// Unauthenticated routes
		auth.SetupRoutes(r, logger)

		// Authenticated routes
		r.Use(authenticator.Require)
		fs.SetupRoutes(r)
		user.SetupRoutes(r)
		publinks.SetupRoutes(r)
		trash.SetupRoutes(r)
		users.SetupRoutes(r)
		admin.SetupRoutes(r)
	}
}
