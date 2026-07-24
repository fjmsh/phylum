package setup

import (
	"fmt"
	"io"
	"net/http"

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

type mailConfig struct {
	SMTP struct {
		Host     string `json:"host" form:"host" koanf:"host"`
		Port     int    `json:"port" form:"port" koanf:"port,omitempty"`
		Username string `json:"username" form:"username" koanf:"username"`
		Password string `json:"password" form:"password" koanf:"password"`
	} `json:"smtp" form:"smtp" koanf:"smtp"`
	From struct {
		Name  string `json:"name" form:"name" koanf:"name,omitempty"`
		Email string `json:"email" form:"email" koanf:"email,omitempty"`
	} `json:"from" form:"from" koanf:"from"`
}

func handleValidateRequest(c *gin.Context) {
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
		response["error"] = "Failed to connect to SMTP server: " + err.Error()
	}
	c.JSON(http.StatusOK, response)

}
