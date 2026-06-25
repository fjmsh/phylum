package mail

import (
	"errors"
	"fmt"
	"net/http"
	"os"
	"syscall"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
)

func handleUpdateRequest(c *gin.Context) {
	var params struct {
		Config mail.Config `json:"config"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		panic(errInvalidParams)
	}
	auth := authenticator.GetAuth(c)
	if !auth.HasScope("admin:" + core.UserPermissionConfigMailUpdate) {
		panic(core.ErrInsufficientScope)
	}
	if !auth.UserPermissions().HasPermission(core.UserPermissionConfigMailUpdate) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to update mail config"))
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
	if _, err := mail.CreateMailer(cfg, *zerolog.Ctx(c.Request.Context())); err != nil {
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
	}
	if response != nil {
		panic(response)
	}
	defer func() {
		syscall.Kill(os.Getpid(), syscall.SIGINT)
	}()

	fullCfg := config.MergeWithYaml(paramsCfg, "mail")
	if err := config.WriteConfig(fullCfg); err != nil {
		panic(core.NewErrorWithDetails(http.StatusInternalServerError, "failed_to_write_config", "Failed to Write Config", err.Error()))
	}
	c.JSON(http.StatusOK, gin.H{})

}
