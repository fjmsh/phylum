package setup

import (
	"io"
	"net/http"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/go-viper/mapstructure/v2"
	"github.com/knadh/koanf/parsers/json"
	"github.com/knadh/koanf/providers/rawbytes"
	"github.com/knadh/koanf/v2"
)

func handleDBValidate(c *gin.Context) {
	params := koanf.New(".")
	decoderConfig := &mapstructure.DecoderConfig{
		ErrorUnused:      true,
		WeaklyTypedInput: true,
	}
	if body, err := io.ReadAll(c.Request.Body); err != nil {
		panic(core.NewError(http.StatusBadRequest, "no_request_body", "failed to read request parameters from body: "+err.Error()))
	} else if err := params.Load(rawbytes.Provider(body), json.Parser()); err != nil {
		panic(core.NewError(http.StatusBadRequest, "parse_failed", "failed to parse request parameters from body: "+err.Error()))
	} else if err := params.UnmarshalWithConf("config", &db.Config{}, koanf.UnmarshalConf{DecoderConfig: decoderConfig}); err != nil {
		panic(core.NewError(http.StatusBadRequest, "validate_failed", "failed to validate request parameters from body: "+err.Error()))
	}

	var cfg db.Config
	config.MergeSub("db", params).Unmarshal("", &cfg)
	overrides := config.HasOverrides("db", params)
	response := gin.H{
		"overrides": overrides,
	}

	if pool, err := db.Connect(c.Request.Context(), cfg, nil); err != nil {
		response["error"] = gin.H{
			"msg":     "Failed to Initialize Connection",
			"details": err.Error(),
		}
	} else if schema, err := db.GetSchemaInfo(c.Request.Context(), pool); err != nil {
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
		} else if strings.Contains(err.Error(), "SQLSTATE 28P01") {
			response["error"] = gin.H{
				"code": "incorrect_password",
				"msg":  "Incorrect Password",
			}
		} else if strings.Contains(err.Error(), "SQLSTATE 3D000") {
			response["error"] = gin.H{
				"code": "database_does_not_exist",
				"msg":  "Database Does Not Exist",
			}
		} else {
			response["error"] = gin.H{
				"msg":     "Failed to Connect to Database",
				"details": err.Error(),
			}
		}
	} else if schema.CurrentVersion != 0 {
		response["warning"] = gin.H{
			"code": "not_empty",
			"msg":  "Database is not empty",
		}
	}
	c.JSON(http.StatusOK, response)
}
