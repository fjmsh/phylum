package setup

import (
	"fmt"
	"io"
	"net/http"
	"strings"

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

func handleMailValidate(c *gin.Context) {
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

	var cfg mail.Config
	if err := config.MergeSub("mail", params).Unmarshal("", &cfg); err != nil {
		fmt.Println(err)
	}

	overrides := config.HasOverrides("mail", params)
	response := gin.H{
		"overrides": overrides,
	}
	mailer := mail.CreateMailer(cfg, *zerolog.Ctx(c.Request.Context()))
	if err := mailer.CheckConnection(); err != nil {
		if strings.Contains(err.Error(), "no such host") {
			response["error"] = gin.H{
				"code":    "no_such_host",
				"msg":     "Failed to connect to SMTP Server",
				"details": "No Such Host",
			}
		} else if strings.Contains(err.Error(), "connection refused") {
			response["error"] = gin.H{
				"code":    "connection_refused",
				"msg":     "Failed to connect to SMTP Server",
				"details": "Connection Refused",
			}
		} else if strings.Contains(err.Error(), "auth failure") {
			response["error"] = gin.H{
				"code":    "auth_failure",
				"msg":     "Failed to connect to SMTP Server",
				"details": "Auth Failure",
			}
		} else if strings.Contains(err.Error(), "timeout") {
			response["error"] = gin.H{
				"code":    "io_timeout",
				"msg":     "Failed to connect to SMTP Server",
				"details": "I/O Timeout",
			}
		} else {
			response["error"] = gin.H{
				"msg":     "Failed to connect to SMTP Server",
				"details": err.Error(),
			}
		}
	}
	c.JSON(http.StatusOK, response)

}
