package setup

import (
	"net/http"
	"strings"

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
		response["error"] = "Connection Error"
		response["details"] = err.Error()
	} else if _, err := db.GetSchemaInfo(c.Request.Context(), pool); err != nil {
		response["success"] = false
		if strings.Contains(err.Error(), "no such host") {
			response["error"] = "No Such Host"
		} else if strings.Contains(err.Error(), "connection refused") {
			response["error"] = "Connection Refused"
		} else if strings.Contains(err.Error(), "SQLSTATE 28P01") {
			response["error"] = "Incorrect Password"
		} else if strings.Contains(err.Error(), "SQLSTATE 3D000") {
			response["error"] = "Database Does Not Exist"
		} else {
			response["error"] = "Unknown Error"
			response["details"] = err.Error()
		}
	}
	c.JSON(http.StatusOK, response)
}
