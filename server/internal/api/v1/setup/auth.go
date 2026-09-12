package setup

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/pbkdf2"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
	"github.com/go-viper/mapstructure/v2"
	"github.com/knadh/koanf/parsers/json"
	"github.com/knadh/koanf/providers/rawbytes"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
)

const timeout = 3 * time.Second

func handleAuthTestArgon2(c *gin.Context) {
	var params struct {
		Memory      uint8  `json:"memory" form:"memory" koanf:"memory,omitempty"`
		Iterations  uint32 `json:"iterations" form:"iterations" koanf:"iterations,omitempty"`
		Parallelism uint8  `json:"parallelism" form:"parallelism" koanf:"parallelism,omitempty"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	paramsCfg := koanf.New(".")
	paramsCfg.Load(structs.Provider(params, "koanf"), nil)

	var cfg argon2.Config
	config.MergeSub("auth.password.crypt.argon2", paramsCfg).Unmarshal("", &cfg)

	start := time.Now()

	timeout := time.NewTimer(timeout)
	errChan := make(chan error)
	go func() {
		_, err := argon2.New(cfg).GenerateEncodedHash("test")
		errChan <- err
	}()

	select {
	case <-timeout.C:
		err = errors.New("Hash generation took too long")
	case e := <-errChan:
		err = e
	}

	var response map[string]interface{}
	if err != nil {
		response = gin.H{
			"success": false,
			"error":   "failed to generate hash: " + err.Error(),
		}
	} else {
		hashTime := time.Since(start)
		response = gin.H{
			"success": true,
			"time":    hashTime.Microseconds(),
		}
	}
	c.JSON(http.StatusOK, response)
}

func handleAuthTestPBKDF2(c *gin.Context) {
	var params struct {
		Function   string `json:"function" form:"function" koanf:"function,omitempty"`
		Iterations int    `json:"iterations" form:"iterations" koanf:"iterations,omitempty"`
	}
	err := c.ShouldBind(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	paramsCfg := koanf.New(".")
	paramsCfg.Load(structs.Provider(params, "koanf"), nil)

	var cfg pbkdf2.Config
	config.MergeSub("auth.password.crypt.pbkdf2", paramsCfg).Unmarshal("", &cfg)

	start := time.Now()
	p, err := pbkdf2.New(cfg)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "failed to instantiate pbkdf2: " + err.Error(),
		})
		return
	}

	timeout := time.NewTimer(timeout)
	errChan := make(chan error)
	go func() {
		_, err := p.GenerateEncodedHash("test")
		errChan <- err
	}()

	select {
	case <-timeout.C:
		err = errors.New("Hash generation took too long")
	case e := <-errChan:
		err = e
	}

	var response map[string]interface{}
	if err != nil {
		response = gin.H{
			"success": false,
			"error":   "failed to generate hash: " + err.Error(),
		}
	} else {
		hashTime := time.Since(start)
		response = gin.H{
			"success": true,
			"time":    hashTime.Microseconds(),
		}
	}
	c.JSON(http.StatusOK, response)
}

func handleAuthValidate(c *gin.Context) {
	params := koanf.New(".")
	decoderConfig := &mapstructure.DecoderConfig{
		ErrorUnused:      true,
		WeaklyTypedInput: true,
		Result:           &auth.Config{},
	}
	if body, err := io.ReadAll(c.Request.Body); err != nil {
		panic(core.NewError(http.StatusBadRequest, "read_failed", "Failed to read request parameters: "+err.Error()))
	} else if err := params.Load(rawbytes.Provider(body), json.Parser()); err != nil {
		panic(core.NewError(http.StatusBadRequest, "parse_failed", "Failed to parse request parameters: "+err.Error()))
	} else if err := params.UnmarshalWithConf("config", nil, koanf.UnmarshalConf{DecoderConfig: decoderConfig}); err != nil {
		panic(core.NewError(http.StatusBadRequest, "validate_failed", "Failed to validate request parameters: "+err.Error()))
	}

	var cfg auth.Config
	if err := config.MergeSub("auth", params).Unmarshal("", &cfg); err != nil {
		fmt.Println(err)
	}
	response := gin.H{}
	if _, err := auth.CreateHandler(cfg, *zerolog.Ctx(c.Request.Context())); err != nil {
		response["error"] = gin.H{
			"msg":     "Invalid Auth Configuration",
			"details": err.Error(),
		}
	}
	c.JSON(http.StatusOK, response)
}
