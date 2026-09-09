package auth

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"syscall"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
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
		Result:           &auth.Config{},
	}
	if body, err := io.ReadAll(c.Request.Body); err != nil {
		panic(core.NewError(http.StatusBadRequest, "no_request_body", "failed to read request parameters from body: "+err.Error()))
	} else if err := params.Load(rawbytes.Provider(body), json.Parser()); err != nil {
		panic(core.NewError(http.StatusBadRequest, "parse_failed", "failed to parse request parameters from body: "+err.Error()))
	} else if err := params.UnmarshalWithConf("config", nil, koanf.UnmarshalConf{DecoderConfig: decoderConfig}); err != nil {
		panic(core.NewError(http.StatusBadRequest, "validate_failed", "failed to validate request parameters from body: "+err.Error()))
	}

	a := authenticator.GetAuth(c)
	if !a.HasScope("admin:" + core.UserPermissionConfigAuthUpdate) {
		panic(core.ErrInsufficientScope)
	}
	if !a.UserPermissions().HasPermission(core.UserPermissionConfigAuthUpdate) {
		panic(core.NewError(http.StatusBadRequest, "insufficient_permissions", "You do not have permissions to update auth config"))
	}

	updates := params.Cut("config")
	var cfg auth.Config
	if err := config.MergeSub("auth", updates).Unmarshal("", &cfg); err != nil {
		fmt.Println(err)
	}
	if _, err := auth.CreateHandler(cfg, *zerolog.Ctx(c.Request.Context())); err != nil {
		panic(core.NewErrorWithDetails(http.StatusBadRequest, "failed_to_initialize_auth", "Failed To Initialize Auth", err.Error()))
	}
	defer func() {
		syscall.Kill(os.Getpid(), syscall.SIGINT)
	}()

	fullCfg := config.MergeWithYaml(updates, "auth")
	if err := config.WriteConfig(fullCfg); err != nil {
		panic(core.NewErrorWithDetails(http.StatusInternalServerError, "failed_to_write_config", "Failed to Write Config", err.Error()))
	}
	c.JSON(http.StatusOK, config.ConfigMapWithUpdates("auth", updates))

}
