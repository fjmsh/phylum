package admin

import (
	"codeberg.org/shroff/phylum/server/internal/api/v1/admin/config"
	"codeberg.org/shroff/phylum/server/internal/api/v1/admin/users"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/admin")
	users.SetupRoutes(group)
	config.SetupRoutes(group)
}
