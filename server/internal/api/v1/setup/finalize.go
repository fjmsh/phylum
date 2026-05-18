package setup

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
)

type finalizeParams struct {
	Config configOverrides `json:"config"`
	User   userConfig      `json:"user"`
}

type configOverrides struct {
	DB   db.Config   `koanf:"db" json:"db"`
	Mail mail.Config `koanf:"mail,omitempty" json:"mail"`
	Auth auth.Config `koanf:"auth" json:"auth"`
}

type userConfig struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func handleFinalize(c *gin.Context) {
	var params finalizeParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	paramsCfg := koanf.New(".")
	paramsCfg.Load(structs.Provider(params.Config, "koanf"), nil)
	paramsCfg.Print()

	c.JSON(http.StatusOK, gin.H{
		"success": true,
	})
}
