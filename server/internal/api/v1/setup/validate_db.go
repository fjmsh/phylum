package setup

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
)

type dbConfig struct {
	Host     string `json:"host" form:"host" koanf:"host,omitempty"`
	Port     int    `json:"port" form:"port" koanf:"port,omitempty"`
	DBName   string `json:"name" form:"name" koanf:"name,omitempty"`
	User     string `json:"user" form:"user" koanf:"user,omitempty"`
	Password string `json:"password" form:"password" koanf:"password,omitempty"`
}

func handleValidateDBRequest(c *gin.Context) {
	var params dbConfig
	err := c.ShouldBindJSON(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	paramsCfg := koanf.New(".")
	paramsCfg.Load(structs.Provider(params, "koanf"), nil)

	var cfg db.Config
	config.MergeSub("db", paramsCfg).Unmarshal("", &cfg)
	overrides := config.HasOverrides("db", paramsCfg)
	response := gin.H{
		"success":   true,
		"overrides": overrides,
	}
	if pool, err := db.Connect(c.Request.Context(), cfg, nil); err != nil {
		response["success"] = false
		response["error"] = "DB Connect Error: " + err.Error()
	} else if _, err := db.GetSchemaInfo(c.Request.Context(), pool); err != nil {
		response["success"] = false
		response["error"] = "DB Query Error: " + err.Error()
	}
	c.JSON(http.StatusOK, response)
}
