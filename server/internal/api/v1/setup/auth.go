package setup

import (
	"errors"
	"net/http"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/pbkdf2"
	"codeberg.org/shroff/phylum/server/internal/config"
	"github.com/gin-gonic/gin"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
)

const timeout = 3 * time.Second

func handleTestArgon2Params(c *gin.Context) {
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

func handleTestPBKDF2Params(c *gin.Context) {
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
