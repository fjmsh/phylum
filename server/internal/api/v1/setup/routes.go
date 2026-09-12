package setup

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

var errInvalidParams = core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/setup")

	group.POST("/db/validate", handleDBValidate)
	group.POST("/mail/validate", handleMailValidate)
	group.POST("/auth/validate", handleAuthValidate)
	group.POST("/auth/test/argon2", handleAuthTestArgon2)
	group.POST("/auth/test/pbkdf2", handleAuthTestPBKDF2)
	group.POST("/finalize", handleFinalize)
}
