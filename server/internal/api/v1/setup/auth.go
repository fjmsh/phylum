package setup

import (
	"net/http"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/pbkdf2"
	"codeberg.org/shroff/phylum/server/internal/config"
	"github.com/gin-gonic/gin"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
)

type argon2Config struct {
	Memory      uint8  `json:"memory" form:"memory" koanf:"memory,omitempty"`
	Iterations  uint32 `json:"iterations" form:"iterations" koanf:"iterations,omitempty"`
	Parallelism uint8  `json:"parallelism" form:"parallelism" koanf:"parallelism,omitempty"`
}

type pbkdf2Config struct {
	Function   string `json:"function" form:"function" koanf:"function,omitempty"`
	Iterations int    `json:"iterations" form:"iterations" koanf:"iterations,omitempty"`
}

func handleTestArgon2Params(c *gin.Context) {
	var params argon2Config
	err := c.ShouldBind(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	paramsCfg := koanf.New(".")
	paramsCfg.Load(structs.Provider(params, "koanf"), nil)

	var cfg argon2.Config
	config.MergeSub("auth.password.crypt.argon2", paramsCfg).Unmarshal("", &cfg)

	start := time.Now()
	_, err = argon2.New(cfg).GenerateEncodedHash("test")
	hashTime := time.Since(start)
	var response map[string]interface{}
	if err != nil {
		response = gin.H{
			"success": false,
			"error":   "failed to generate hash: " + err.Error(),
		}
	} else {
		response = gin.H{
			"success": true,
			"time":    hashTime.Microseconds(),
		}
	}
	c.JSON(http.StatusOK, response)
}

func handleTestPBKDF2Params(c *gin.Context) {
	var params pbkdf2Config
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

	_, err = p.GenerateEncodedHash("test")
	hashTime := time.Since(start)
	var response map[string]interface{}
	if err != nil {
		response = gin.H{
			"success": false,
			"error":   "failed to generate hash: " + err.Error(),
		}
	} else {
		response = gin.H{
			"success": true,
			"time":    hashTime.Microseconds(),
		}
	}
	c.JSON(http.StatusOK, response)
}
