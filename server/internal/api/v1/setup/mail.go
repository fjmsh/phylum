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
	var params mailConfig
	err := c.ShouldBindJSON(&params)
	if err != nil {
		panic(errInvalidParams)
	}
	paramsCfg := koanf.New(".")
	paramsCfg.Load(structs.Provider(params, "koanf"), nil)

	var cfg mail.Config
	if err := config.MergeSub("mail", paramsCfg).Unmarshal("", &cfg); err != nil {
		fmt.Println(err)
	}
	overrides := config.HasOverrides("mail", paramsCfg)
	response := gin.H{
		"overrides": overrides,
	}
	mailer := mail.CreateMailer(cfg, *zerolog.Ctx(c.Request.Context()))
	if err := mailer.CheckConnection(); err != nil {
		response["error"] = gin.H{
			"msg": "Failed to connect to SMTP server: " + err.Error(),
		}
	}
	c.JSON(http.StatusOK, response)

}
