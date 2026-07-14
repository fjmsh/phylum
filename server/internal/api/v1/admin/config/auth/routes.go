package auth

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/auth")
	group.GET("/read", handleReadRequest)
	group.POST("/update", handleUpdateRequest)
	group.POST("/test/argon2", handleTestArgon2Params)
	group.POST("/test/pbkdf2", handleTestPBKDF2Params)
}

func handleReadRequest(c *gin.Context) {
	a := authenticator.GetAuth(c)
	if !a.HasScope("admin:" + core.UserPermissionConfigAuthRead) {
		panic(core.ErrInsufficientScope)
	}
	if !a.UserPermissions().HasPermission(core.UserPermissionConfigAuthRead) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to read auth config"))
	}

	c.JSON(http.StatusOK, auth.Get().Configuration())
}
