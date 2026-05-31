package setup

import (
	"fmt"
	"net/http"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
)

type mailConfig struct {
	SMTP   smtpConfig `json:"smtp" form:"smtp" koanf:"smtp"`
	From   fromConfig `json:"from" form:"from" koanf:"from"`
	SendTo string     `json:"send_to" form:"send_to" koanf:"-"`
}

type smtpConfig struct {
	Host     string `json:"host" form:"host" koanf:"host"`
	Port     int    `json:"port" form:"port" koanf:"port,omitempty"`
	Username string `json:"username" form:"username" koanf:"username"`
	Password string `json:"password" form:"password" koanf:"password"`
}

type fromConfig struct {
	Name  string `json:"name" form:"name" koanf:"name,omitempty"`
	Email string `json:"email" form:"email" koanf:"email,omitempty"`
}

func handleSendTestEmailRequest(c *gin.Context) {
	var params mailConfig
	err := c.ShouldBindJSON(&params)
	if err != nil {
		panic(errInvalidParams)
	}
	paramsCfg := koanf.New(".")
	if params.From.Email == "" {
		params.From.Email = params.SMTP.Username
	}
	paramsCfg.Load(structs.Provider(params, "koanf"), nil)

	var cfg mail.Config
	if err := config.MergeSub("mail", paramsCfg).Unmarshal("", &cfg); err != nil {
		fmt.Println(err)
	}
	overrides := config.HasOverrides("mail", paramsCfg)
	response := gin.H{
		"overrides": overrides,
	}
	if mailer, err := mail.CreateMailer(cfg, *zerolog.Ctx(c.Request.Context())); err != nil {
		response["error"] = gin.H{
			"code":    "generic",
			"msg":     "Failed to Create Mailer",
			"details": err.Error(),
		}
	} else if err := mailer.SendTestEmail(params.SendTo); err != nil {
		if strings.Contains(err.Error(), "no such host") {
			response["error"] = gin.H{
				"code": "no_such_host",
				"msg":  "No Such Host",
			}
		} else if strings.Contains(err.Error(), "connection refused") {
			response["error"] = gin.H{
				"code": "connection_refused",
				"msg":  "Connection Refused",
			}
		} else if strings.Contains(err.Error(), "timeout") {
			response["error"] = gin.H{
				"code": "io_timeout",
				"msg":  "I/O Timeout",
			}
		} else {
			response["error"] = gin.H{
				"code":    "generic",
				"msg":     "Failed to Send Mail",
				"details": err.Error(),
			}
		}
	}
	c.JSON(http.StatusOK, response)

}
