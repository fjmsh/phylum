package config

import (
	"codeberg.org/shroff/phylum/server/internal/api/v1/admin/config/mail"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/config")
	mail.SetupRoutes(group)
}
