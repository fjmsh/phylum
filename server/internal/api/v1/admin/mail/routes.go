package users

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
)

var errInvalidParams = core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/users")
	group.GET("/settings", handleSettingsRequest)
}

func handleSettingsRequest(c *gin.Context) {
	auth := authenticator.GetAuth(c)
	if !auth.HasScope("admin:" + core.UserPermissionConfigMailRead) {
		panic(core.ErrInsufficientScope)
	}
	if !auth.UserPermissions().HasPermission(core.UserPermissionConfigMailRead) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to change user passwords"))
	}

	c.JSON(http.StatusOK, mail.Configuration())
}
