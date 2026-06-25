package mail

import (
	"errors"
	"fmt"
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
)

var errInvalidParams = core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/mail")
	group.GET("/read", handleReadRequest)
	group.POST("/validate", handleValidateRequest)
}

func handleReadRequest(c *gin.Context) {
	auth := authenticator.GetAuth(c)
	if !auth.HasScope("admin:" + core.UserPermissionConfigMailRead) {
		panic(core.ErrInsufficientScope)
	}
	if !auth.UserPermissions().HasPermission(core.UserPermissionConfigMailRead) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to read mail config"))
	}

	c.JSON(http.StatusOK, mail.Configuration())
}

func handleValidateRequest(c *gin.Context) {
	var params struct {
		Config mail.Config `json:"config"`
		SendTo string      `json:"send_to"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		panic(errInvalidParams)
	}
	auth := authenticator.GetAuth(c)
	if !auth.HasScope("admin:" + core.UserPermissionConfigMailValidate) {
		panic(core.ErrInsufficientScope)
	}
	if !auth.UserPermissions().HasPermission(core.UserPermissionConfigMailValidate) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to validate mail config"))
	}

	paramsCfg := koanf.New(".")
	if params.Config.From.Email == "" {
		params.Config.From.Email = params.Config.SMTP.Username
	}
	paramsCfg.Load(structs.Provider(params.Config, "koanf"), nil)

	var cfg mail.Config
	if err := config.MergeSub("mail", paramsCfg).Unmarshal("", &cfg); err != nil {
		fmt.Println(err)
	}
	var response *core.Error
	cfg.OmitStartupCheck = params.SendTo != ""
	if mailer, err := mail.CreateMailer(cfg, *zerolog.Ctx(c.Request.Context())); err != nil {
		if errors.Is(err, mail.ErrNoSuchHost) {
			response = core.NewError(http.StatusBadRequest, "smtp_host_not_found", "SMTP Host Not Found")
		} else if errors.Is(err, mail.ErrConnectionRefused) {
			response = core.NewError(http.StatusBadRequest, "smtp_connection_refused", "SMTP Connection Refused")
		} else if errors.Is(err, mail.ErrIOTimeout) {
			response = core.NewError(http.StatusBadRequest, "smtp_io_timeout", "SMTP I/O Timeout")
		} else if errors.Is(err, mail.ErrAuthFailure) {
			response = core.NewError(http.StatusBadRequest, "smtp_auth_failure", "SMTP Auth Failure")
		} else {
			response = core.NewErrorWithDetails(http.StatusBadRequest, "failed_to_create_mailer", "Failed To Create Mailer", err.Error())
		}
	} else if params.SendTo != "" {
		if err := mailer.SendTestEmail(params.SendTo); err != nil {
			if errors.Is(err, mail.ErrNoSuchHost) {
				response = core.NewError(http.StatusBadRequest, "smtp_host_not_found", "SMTP Host Not Found")
			} else if errors.Is(err, mail.ErrConnectionRefused) {
				response = core.NewError(http.StatusBadRequest, "smtp_connection_refused", "SMTP Connection Refused")
			} else if errors.Is(err, mail.ErrIOTimeout) {
				response = core.NewError(http.StatusBadRequest, "smtp_io_timeout", "SMTP I/O Timeout")
			} else if errors.Is(err, mail.ErrAuthFailure) {
				response = core.NewError(http.StatusBadRequest, "smtp_auth_failure", "SMTP Auth Failure")
			} else {
				response = core.NewErrorWithDetails(http.StatusBadRequest, "failed_to_send_mail", "Failed to Send Mail", err.Error())
			}
		}
	}
	if response == nil {
		c.JSON(http.StatusOK, gin.H{})
	} else {
		c.AbortWithStatusJSON(response.Status, response)
	}

}
