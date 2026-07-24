package setup

import (
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

func handleFinalize(c *gin.Context) {
	var params struct {
		Config struct {
			DB   db.Config   `koanf:"db,omitempty" json:"db"`
			Mail mail.Config `koanf:"mail,omitempty" json:"mail"`
			Auth auth.Config `koanf:"auth,omitempty" json:"auth"`
			Core core.Config `koanf:"core,omitempty"`
		} `json:"config"`
		User struct {
			Email    string `json:"email"`
			Name     string `json:"name"`
			Password string `json:"password"`
		} `json:"user"`
		Options struct {
			DB struct {
				Wipe bool `json:"wipe"`
			} `json:"db"`
		}
	}
	err := c.ShouldBindJSON(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	inCfg := koanf.New(".")
	inCfg.Load(structs.Provider(params.Config, "koanf"), nil)
	fullCfg := config.MergeSub("", inCfg)

	var dbConfig db.Config
	var mailConfig mail.Config
	var authConfig auth.Config
	var coreConfig core.Config
	fullCfg.Unmarshal("db", &dbConfig)
	fullCfg.Unmarshal("mail", &mailConfig)
	fullCfg.Unmarshal("auth", &authConfig)
	fullCfg.Unmarshal("core", &coreConfig)

	defer func() {
		syscall.Kill(os.Getpid(), syscall.SIGINT)
	}()

	logger := zerolog.Logger{}
	if params.Options.DB.Wipe {
		dbConfig.NoMigrate = true
	}

	if pool, err := db.Initialize(c.Request.Context(), dbConfig, &logger); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize DB",
			"details": err.Error(),
		})
		return
	} else if params.Options.DB.Wipe {
		if err := db.ResetSchema(c.Request.Context(), pool); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"error":   "Failed to Reset DB Schema",
				"details": err.Error(),
			})

		} else if schemaInfo, err := db.GetSchemaInfo(c.Request.Context(), pool); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"error":   "Failed get DB Schema Info",
				"details": err.Error(),
			})
		} else if err := schemaInfo.MigrateTo(c.Request.Context(), schemaInfo.LatestVersion); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"error":   "Failed migrate DB Schema",
				"details": err.Error(),
			})
		}
	}
	d := db.Get(c.Request.Context())

	if err := core.Initialize(d, coreConfig); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize core",
			"details": err.Error(),
		})
		return
	}
	if err := auth.Initialize(authConfig, logger); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize auth",
			"details": err.Error(),
		})
		return
	}
	if params.User.Password != "" && !auth.Get().PasswordBackendSupportsUpdate() {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Attempting to set password when backend doesn't support it",
		})
		return
	}
	m := mail.CreateMailer(mailConfig, logger)
	mail.SetDefaultMailer(m)
	if m.Enabled() && mailConfig.ConnectionCheckFatal {
		if err := m.CheckConnection(); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"error":   "Failed to connect to SMTP server: " + err.Error(),
			})
		}
	}

	err = d.RunInTx(func(db db.TxHandler) error {
		if user, err := core.CreateUser(db, params.User.Email, params.User.Name, false); err != nil {
			return err
		} else {
			if params.User.Password != "" {
				// Already checked that the password backend supports update
				if err := auth.Get().UpdateUserPassword(db, params.User.Email, params.User.Password); err != nil {
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
