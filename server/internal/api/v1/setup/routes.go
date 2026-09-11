package setup

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

var errInvalidParams = core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/setup")

	group.POST("/db/validate", handleValidateDBRequest)
	group.POST("/mail/validate", handleValidateRequest)
	group.POST("/auth/test/argon2", handleTestArgon2Params)
	group.POST("/auth/test/pbkdf2", handleTestPBKDF2Params)
	group.POST("/finalize", handleFinalize)
}
