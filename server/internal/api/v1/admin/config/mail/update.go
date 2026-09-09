package mail

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"syscall"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/go-viper/mapstructure/v2"
	"github.com/knadh/koanf/parsers/json"
	"github.com/knadh/koanf/providers/rawbytes"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
)

func handleUpdateRequest(c *gin.Context) {
	params := koanf.New(".")
	decoderConfig := &mapstructure.DecoderConfig{
		ErrorUnused:      true,
		WeaklyTypedInput: true,
		Result:           &mail.Config{},
	}
	if body, err := io.ReadAll(c.Request.Body); err != nil {
		panic(core.NewError(http.StatusBadRequest, "no_request_body", "failed to read request parameters from body: "+err.Error()))
	} else if err := params.Load(rawbytes.Provider(body), json.Parser()); err != nil {
		panic(core.NewError(http.StatusBadRequest, "parse_failed", "failed to parse request parameters from body: "+err.Error()))
	} else if err := params.UnmarshalWithConf("config", nil, koanf.UnmarshalConf{DecoderConfig: decoderConfig}); err != nil {
		panic(core.NewError(http.StatusBadRequest, "validate_failed", "failed to validate request parameters from body: "+err.Error()))
	}

	auth := authenticator.GetAuth(c)
	if !auth.HasScope("admin:" + core.UserPermissionConfigMailUpdate) {
		panic(core.ErrInsufficientScope)
	}
	if !auth.UserPermissions().HasPermission(core.UserPermissionConfigMailUpdate) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to update mail config"))
	}

	updates := params.Cut("config")
	var cfg mail.Config
	if err := config.MergeSub("mail", updates).Unmarshal("", &cfg); err != nil {
		fmt.Println(err)
	}
	var response *core.Error
	mailer := mail.CreateMailer(cfg, *zerolog.Ctx(c.Request.Context()))
	if err := mailer.CheckConnection(); err != nil {
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

	fullCfg := config.MergeWithYaml(updates, "mail")
	if err := config.WriteConfig(fullCfg); err != nil {
		panic(core.NewErrorWithDetails(http.StatusInternalServerError, "failed_to_write_config", "Failed to Write Config", err.Error()))
	}
	c.JSON(http.StatusOK, config.ConfigMapWithUpdates("mail", updates))

}
