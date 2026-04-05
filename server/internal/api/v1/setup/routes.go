package setup

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

var errInvalidParams = core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/setup")

	group.POST("/validate_db", handleValidateDBRequest)
	group.POST("/send_test_mail", handleSendTestEmailRequest)
	group.GET("/auth/test_argon2_params", handleTestArgon2Params)
	group.GET("/auth/test_pbkdf2_params", handleTestPBKDF2Params)
}
