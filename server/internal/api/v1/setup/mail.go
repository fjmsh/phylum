package setup

import (
	"fmt"
	"net/http"

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
	b := make([]byte, 1024)
	c.Request.Body.Read(b)
	fmt.Println(string(b))

	paramsCfg := koanf.New(".")
	if params.From.Email == "" {
		params.From.Email = params.SMTP.Username
	}
	paramsCfg.Load(structs.Provider(params, "koanf"), nil)

	var cfg mail.Config
	if err := config.MergeSub("mail", paramsCfg).Unmarshal("", &cfg); err != nil {
		fmt.Println(err)
	}
	fmt.Printf("%+v\n", cfg)
	overrides := config.HasOverrides("mail", paramsCfg)
	response := gin.H{
		"success":   true,
		"overrides": overrides,
	}
	if mailer, err := mail.CreateMailer(cfg, *zerolog.Ctx(c.Request.Context())); err != nil {
		response["success"] = false
		response["error"] = "Mailer Create Error: " + err.Error()
	} else if err := mailer.SendTestEmail(params.SendTo); err != nil {
		response["success"] = false
		response["error"] = "Mail Send Error: " + err.Error()
	}
	c.JSON(http.StatusOK, response)

}
