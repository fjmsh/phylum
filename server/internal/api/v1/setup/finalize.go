package setup

import (
	"errors"
	"net/http"
	"os"
	"syscall"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
)

type finalizeParams struct {
	Config configOverrides `json:"config"`
	User   userConfig      `json:"user"`
}

type configOverrides struct {
	DB   db.Config   `koanf:"db" json:"db"`
	Mail mail.Config `koanf:"mail,omitempty" json:"mail"`
	Auth auth.Config `koanf:"auth" json:"auth"`
	Core core.Config `koanf:"core,omitempty"`
}

type userConfig struct {
	Email    string `json:"email"`
	Name     string `json:"name"`
	Password string `json:"password"`
}

func handleFinalize(c *gin.Context) {
	var params finalizeParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	inCfg := koanf.New(".")
	inCfg.Load(structs.Provider(params.Config, "koanf"), nil)
	fullCfg := config.MergeSub("", inCfg)

	var cfg configOverrides
	fullCfg.Unmarshal("", &cfg)

	defer func() {
		syscall.Kill(os.Getpid(), syscall.SIGINT)
	}()

	logger := zerolog.Logger{}
	if _, err := db.Initialize(c.Request.Context(), cfg.DB, &logger); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize DB",
			"details": err.Error(),
		})
		return
	}
	d := db.Get(c.Request.Context())
	if users, err := core.ListUsers(d, 0); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to list users",
			"details": err.Error(),
		})
		return
	} else if len(users) != 0 {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Database not empty",
		})
		return
	}

	if err := core.Initialize(d, cfg.Core); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize core",
			"details": err.Error(),
		})
		return
	}
	if err := auth.Initialize(cfg.Auth, logger); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize auth",
			"details": err.Error(),
		})
		return
	}
	if m, err := mail.CreateMailer(cfg.Mail, logger); err != nil {
		if !errors.Is(err, mail.ErrEmailNotConfigured) {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"error":   "Failed to initialize mail",
				"details": err.Error(),
			})
			return
		}
	} else {
		mail.SetDefaultMailer(m)
	}

	err = d.RunInTx(func(db db.TxHandler) error {
		if user, err := core.CreateUser(db, params.User.Email, params.User.Name, false); err != nil {
			return err
		} else {
			if params.User.Password != "" {
				if err := auth.UpdateUserPassword(db, params.User.Email, params.User.Password); err != nil {
					return err
				}
			}
			core.SetUserPermissions(db, user.ID, []core.UserPermission{"*"})
		}
		return nil
	})
	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to create user",
			"details": err.Error(),
		})
		return
	}

	config.WriteConfig(inCfg)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
	})

}
