package admin

import (
	"net/http"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/admin/config"
	"codeberg.org/shroff/phylum/server/internal/api/v1/admin/user"
	"codeberg.org/shroff/phylum/server/internal/api/v1/admin/users"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/admin")
	prefix := group.BasePath() + "/"
	group.Use(func(c *gin.Context) {
		path, _ := strings.CutPrefix(c.Request.URL.Path, prefix)
		permission := strings.ReplaceAll(path, "/", ":")
		auth := authenticator.GetAuth(c)
		if !auth.UserPrivileges().HasPermission(permission) {
			panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have sufficient permissions"))
		}
	})
	user.SetupRoutes(group)
	users.SetupRoutes(group)
	config.SetupRoutes(group)
}
